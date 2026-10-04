unit Vigia.UI.Notify;

{ Aviso de área de trabalho com a cara da ComponentesUI: janela sem borda,
  sempre por cima, no canto inferior direito da área útil, empilhando de baixo
  para cima. Some sozinho depois de alguns segundos (pausa com o mouse em cima). }

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Messages,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ExtCtrls,
  UI.Tokens;

type
  TNotifyOpenEvent = procedure(const AKey: string; AAccountId: Integer) of object;

  TNotifyPopup = class(TForm)
  private
    FKey: string;
    FAccountId: Integer;
    FUrl: string;
    FLife: TTimer;
    FFade: TTimer;
    FClosing: Boolean;
    FTargetX, FTargetY: Integer;  // posição para onde o aviso está indo
    FPlaced: Boolean;             // já tem posição na tela
    procedure LifeTick(Sender: TObject);
    procedure FadeTick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure DetailClick(Sender: TObject);
    procedure DismissClick(Sender: TObject);
    procedure StartClose;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
  end;

  TNotifyManager = class
  private
    class var FPopups: TList<TNotifyPopup>;
    class var FOnOpenDetail: TNotifyOpenEvent;
    class var FMover: TTimer;
    class procedure Reflow;
    class procedure MoverTick(Sender: TObject);
    class procedure Forget(APopup: TNotifyPopup);
  public
    class constructor Create;
    class destructor Destroy;
    { ATone colore a barra lateral. AKey/AAccountId vazios = aviso sem issue. }
    class procedure Show(const ATitle, ABody, AUrl: string; ATone: TUISemanticTone;
      const AKey: string = ''; AAccountId: Integer = 0; ADurationMs: Integer = 8000);
    class property OnOpenDetail: TNotifyOpenEvent read FOnOpenDetail write FOnOpenDetail;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  System.UITypes,
  Winapi.Windows,
  Winapi.ShellAPI,
  Winapi.Dwmapi,
  UI.Theme,
  UI.Painter.Vcl,
  UI.Labels,
  UI.Button;

const
  PopupW = 380;
  PopupH = 132;
  Gap = 10;
  MaxPopups = 4;
  FadeStep = 40;
  SlideDistance = 48;

function ToneColor(ATone: TUISemanticTone): TAlphaColor;
var
  C: TUIColorTokens;
begin
  C := UITheme.Tokens.Color;
  case ATone of
    stPrimary: Result := C.Primary;
    stInfo: Result := C.Info;
    stSuccess: Result := C.Success;
    stWarning: Result := C.Warning;
    stError: Result := C.Error;
  else
    Result := C.FGMuted;
  end;
end;

{ ── Popup ───────────────────────────────────────────────────────────────── }

procedure TNotifyPopup.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // Não rouba foco, não aparece na barra de tarefas, fica por cima.
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE or WS_EX_TOPMOST;
  Params.WndParent := 0;
end;

procedure TNotifyPopup.CreateWnd;
const
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWCP_ROUND = 2;
var
  Pref: Integer;
begin
  inherited;
  // Cantos arredondados do Windows 11 (no 10 o atributo é ignorado).
  Pref := DWMWCP_ROUND;
  DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @Pref, SizeOf(Pref));
end;

{ O TCustomForm mostra com SW_SHOWNORMAL (ativa e rouba o foco). Aqui o VCL
  continua marcando o form e os filhos como visíveis, mas a janela aparece
  sem ativar. }
procedure TNotifyPopup.CMShowingChanged(var Message: TMessage);
begin
  if Showing then
    ShowWindow(Handle, SW_SHOWNOACTIVATE)
  else
    ShowWindow(Handle, SW_HIDE);
end;

procedure TNotifyPopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  // Clicar nos botões não tira o foco do app em que o usuário está.
  Message.Result := MA_NOACTIVATE;
end;

procedure TNotifyPopup.LifeTick(Sender: TObject);
var
  P: TPoint;
begin
  // Mouse em cima segura o aviso.
  GetCursorPos(P);
  if PtInRect(BoundsRect, P) then
    Exit;
  StartClose;
end;

procedure TNotifyPopup.StartClose;
begin
  FLife.Enabled := False;
  FClosing := True;
  // Sai deslizando para a direita enquanto some.
  FTargetX := FTargetX + ScaleValue(SlideDistance);
  TNotifyManager.FMover.Enabled := True;
  FFade.Enabled := True;
end;

procedure TNotifyPopup.FadeTick(Sender: TObject);
begin
  if FClosing then
  begin
    if AlphaBlendValue <= FadeStep then
    begin
      FFade.Enabled := False;
      Close;
      Exit;
    end;
    AlphaBlendValue := AlphaBlendValue - FadeStep;
  end
  else
  begin
    AlphaBlendValue := Min(255, AlphaBlendValue + FadeStep);
    if AlphaBlendValue = 255 then
      FFade.Enabled := False;
  end;
end;

procedure TNotifyPopup.OpenClick(Sender: TObject);
begin
  if FUrl <> '' then
    ShellExecute(0, 'open', PChar(FUrl), nil, nil, SW_SHOWNORMAL);
  StartClose;
end;

procedure TNotifyPopup.DetailClick(Sender: TObject);
begin
  if Assigned(TNotifyManager.FOnOpenDetail) then
    TNotifyManager.FOnOpenDetail(FKey, FAccountId);
  StartClose;
end;

procedure TNotifyPopup.DismissClick(Sender: TObject);
begin
  StartClose;
end;

procedure TNotifyPopup.DoClose(var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
  TNotifyManager.Forget(Self);
end;

{ ── Gerente ─────────────────────────────────────────────────────────────── }

class constructor TNotifyManager.Create;
begin
  FPopups := TList<TNotifyPopup>.Create;
  FMover := TTimer.Create(nil);
  FMover.Interval := 15;
  FMover.Enabled := False;
  FMover.OnTimer := MoverTick;
end;

class destructor TNotifyManager.Destroy;
begin
  FMover.Free;
  FPopups.Free;
end;

class procedure TNotifyManager.Forget(APopup: TNotifyPopup);
begin
  FPopups.Remove(APopup);
  Reflow;
end;

{ Empilha de baixo para cima na área útil do monitor principal. }
class procedure TNotifyManager.Reflow;
var
  Work: TRect;
  I, Y: Integer;
  P: TNotifyPopup;
begin
  Work := Screen.WorkAreaRect;
  Y := Work.Bottom;
  for I := FPopups.Count - 1 downto 0 do
  begin
    P := FPopups[I];
    Y := Y - P.Height - P.ScaleValue(Gap);
    if not P.FClosing then
      P.FTargetX := Work.Right - P.Width - P.ScaleValue(Gap);
    P.FTargetY := Y;
    if not P.FPlaced then
    begin
      // Novo: nasce já na altura certa, deslocado à direita, e desliza para dentro.
      P.FPlaced := True;
      SetWindowPos(P.Handle, HWND_TOPMOST, P.FTargetX + P.ScaleValue(SlideDistance), Y, 0, 0,
        SWP_NOSIZE or SWP_NOACTIVATE);
    end;
  end;
  FMover.Enabled := True;
end;

{ Aproxima cada aviso do alvo (30% por quadro): entrada deslizando e a pilha
  descendo suave quando um aviso sai. }
class procedure TNotifyManager.MoverTick(Sender: TObject);
var
  P: TNotifyPopup;
  R: TRect;
  X, Y: Integer;
  Moving: Boolean;
begin
  Moving := False;
  for P in FPopups do
  begin
    if not P.HandleAllocated then
      Continue;
    GetWindowRect(P.Handle, R);
    X := R.Left + Round((P.FTargetX - R.Left) * 0.3);
    Y := R.Top + Round((P.FTargetY - R.Top) * 0.3);
    if Abs(P.FTargetX - X) <= 1 then
      X := P.FTargetX;
    if Abs(P.FTargetY - Y) <= 1 then
      Y := P.FTargetY;
    if (X <> R.Left) or (Y <> R.Top) then
    begin
      SetWindowPos(P.Handle, HWND_TOPMOST, X, Y, 0, 0, SWP_NOSIZE or SWP_NOACTIVATE);
      Moving := True;
    end;
  end;
  FMover.Enabled := Moving;
end;

class procedure TNotifyManager.Show(const ATitle, ABody, AUrl: string; ATone: TUISemanticTone;
  const AKey: string; AAccountId: Integer; ADurationMs: Integer);
var
  F: TNotifyPopup;
  Accent, Body, Foot: TPanel;
  Lbl: TUILabel;
  Btn: TUIButton;
begin
  // Muitos de uma vez: o mais antigo sai para caber o novo.
  while FPopups.Count >= MaxPopups do
    FPopups[0].Close;

  F := TNotifyPopup.CreateNew(nil);
  F.FKey := AKey;
  F.FAccountId := AAccountId;
  F.FUrl := AUrl;
  F.BorderStyle := bsNone;
  F.FormStyle := fsStayOnTop;
  F.Position := poDesigned;
  F.Color := UIThemeVclBackground;
  F.DoubleBuffered := True;
  F.AlphaBlend := True;
  F.AlphaBlendValue := 0;
  F.ClientWidth := F.ScaleValue(PopupW);
  F.ClientHeight := F.ScaleValue(PopupH);

  Accent := TPanel.Create(F);
  Accent.BevelOuter := bvNone;
  Accent.ParentBackground := False;
  Accent.Color := UIAlphaToVclColor(ToneColor(ATone));
  Accent.Width := F.ScaleValue(5);
  Accent.Align := alLeft;
  Accent.Parent := F;

  Body := TPanel.Create(F);
  Body.BevelOuter := bvNone;
  Body.ParentBackground := False;
  Body.Color := UIThemeVclBackground;
  Body.Padding.SetBounds(F.ScaleValue(14), F.ScaleValue(10), F.ScaleValue(10), F.ScaleValue(6));
  Body.Align := alClient;
  Body.Parent := F;

  Foot := TPanel.Create(F);
  Foot.BevelOuter := bvNone;
  Foot.ParentBackground := False;
  Foot.Color := UIThemeVclBackground;
  Foot.Height := F.ScaleValue(34);
  Foot.Align := alBottom;
  Foot.Parent := Body;

  Btn := TUIButton.Create(F);
  Btn.Caption := 'Dispensar';
  Btn.Variant := bvGhost;
  Btn.Size := bsSM;
  Btn.AutoWidth := True;
  Btn.OnClick := F.DismissClick;
  Btn.Align := alRight;
  Btn.Parent := Foot;
  if AUrl <> '' then
  begin
    Btn := TUIButton.Create(F);
    Btn.Caption := 'Abrir';
    Btn.Variant := bvGhost;
    Btn.Size := bsSM;
    Btn.AutoWidth := True;
    Btn.OnClick := F.OpenClick;
    Btn.AlignWithMargins := True;
    Btn.Margins.SetBounds(0, 0, 4, 0);
    Btn.Align := alRight;
    Btn.Parent := Foot;
  end;
  if AKey <> '' then
  begin
    Btn := TUIButton.Create(F);
    Btn.Caption := IfThen(AKey = '*update', 'Atualizar', 'Ver no Vigia');
    Btn.Size := bsSM;
    Btn.AutoWidth := True;
    Btn.OnClick := F.DetailClick;
    Btn.AlignWithMargins := True;
    Btn.Margins.SetBounds(0, 0, 4, 0);
    Btn.Align := alRight;
    Btn.Parent := Foot;
  end;

  Lbl := TUILabel.Create(F);
  Lbl.Caption := ATitle;
  Lbl.Bold := True;
  Lbl.AutoSize := False;
  Lbl.Height := F.ScaleValue(20);
  Lbl.Parent := Body;
  Lbl.Top := 0;
  Lbl.Align := alTop;

  Lbl := TUILabel.Create(F);
  Lbl.Caption := ABody;
  Lbl.Variant := lvMuted;
  Lbl.WordWrap := True;
  Lbl.AutoSize := False;
  Lbl.AlignWithMargins := True;
  Lbl.Margins.SetBounds(0, F.ScaleValue(4), 0, 0);
  Lbl.Parent := Body;
  Lbl.Top := 1000;
  Lbl.Align := alClient;

  F.FLife := TTimer.Create(F);
  F.FLife.Interval := ADurationMs;
  F.FLife.OnTimer := F.LifeTick;
  F.FFade := TTimer.Create(F);
  F.FFade.Interval := 20;
  F.FFade.OnTimer := F.FadeTick;

  FPopups.Add(F);
  F.HandleNeeded;
  Reflow;
  F.Visible := True;
  F.FFade.Enabled := True;
  F.FLife.Enabled := True;
end;
end.
