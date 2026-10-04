unit Vigia.UI.Main;

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Types,
  System.Generics.Collections,
  System.Notification,
  System.Skia,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Menus,
  Vcl.ExtCtrls,
  UI.Theme,
  UI.Tokens,
  UI.Button,
  UI.Input,
  UI.Select,
  UI.Swap,
  UI.Status,
  UI.Dropdown,
  UI.Kbd,
  UI.Labels,
  UI.Alert,
  UI.FilterChip,
  UI.EmptyState,
  UI.Skeleton,
  UI.ProgressBar,
  UI.Tabs,
  UI.Toggle,
  UI.NumberInput,
  UI.ContextMenu,
  UI.CommandPalette,
  UI.VirtualList,
  UI.ScrollArea,
  UI.Assistant,
  UI.Animations,
  UI.PageTransition,
  UI.CommandSearch,
  UI.Assistant.Types,
  UI.RadialProgress,
  UI.TimePicker,
  UI.Stat,
  UI.Sparkline,
  Vigia.AI,
  Vigia.Model,
  Vigia.UI.Common,
  Vigia.UI.Views,
  Vigia.UI.Detail,
  Vigia.Update;

type
  TItemFilter = (ifMine, ifOverdue, ifReview, ifManual, ifFlagged, ifMyPrs, ifSprint);
  TPage = (pgDashboard, pgIssues, pgAccounts, pgSettings);

  TMainForm = class(TForm)
  private
    FTray: TTrayIcon;
    FTrayMenu: TPopupMenu;
    FAutostartItem: TMenuItem;
    FUpdateItem: TMenuItem;          // "Atualizar para x.y.z", só com versão nova
    FUpdate: TUpdateInfo;            // última release mais nova encontrada
    FUpdateBusy: Boolean;
    FUpdateMode: TUISelect;
    FUpdateBtn: TUIButton;
    FNotifier: TNotificationCenter;
    // Shell
    FTabs: TUITabs;
    FStatusDot: TUIStatus;
    FFooter: TPanel;               // atalhos; igual em todas as abas (FAB não pula)
    FHoursLabel: TUILabel;         // Jira: horas lançadas hoje e na semana
    FHoursToday, FHoursWeek: Double;
    FFooterActions: TArray<TProc>;
    FTabBadges: string;            // contadores com que as abas foram montadas
    FFetchingRate: Boolean;        // cotação do dólar em andamento
    FAccountBtn: TUIButton;
    FRepoBtn: TUIButton;            // filtro de repositório (GitHub), vale para Issues e Dashboard
    FRepoMenu: TUIDropdown;
    FRepoFilter: string;            // 'dono/repo'; vazio = todos
    FAccountMenu: TUIDropdown;
    FAccountFilter: Integer;  // 0 = todas as contas
    FPollMs: Integer;         // cache do intervalo de busca
    FNextRing: TUIRadialProgress;
    FTransition: TUIPageTransition;
    FDetailAnim: TUIAnimation;
    FFlashAnim: TUIAnimation;
    FFlashValue: Single;
    FFlashKeys: TDictionary<string, Boolean>;  // 'conta|CHAVE' mudou nesta busca
    FNewKeys: TDictionary<string, Boolean>;    // 'conta|CHAVE' apareceu nesta busca
    FMuted: TDictionary<string, Boolean>;
    FAccountsBox: TUIScrollArea;
    FPending: TArray<TEvent>;                  // avisos segurados pelo "não perturbe"
    FLastMinuteCheck: Integer;
    FSummaryToggle: TUIToggle;
    // IA automática (tudo desligado por padrão)
    FAiCap: TUINumberInput;
    FAiCheap: TUIInput;
    FAiAuto: array[0..3] of TUIToggle;  // resumo, risco, rascunho de horas, causa do CI
    FSummaryTime: TUITimePicker;
    FDndToggle: TUIToggle;
    FDndStart: TUITimePicker;
    FDndEnd: TUITimePicker;
    FAiProvider: TUISelect;
    FAiBaseUrl: TUIInput;
    FAiModel: TUIInput;
    FAiModelsBtn: TUIButton;
    FAiModelsMenu: TUIDropdown;
    FAiPriceIn: TUINumberInput;
    FAiPriceOut: TUINumberInput;
    FAiStats: array[0..3] of TUIStat;
    FAiCostSpark: TUISparkline;
    FAiLoading: Boolean;
    FThemeSwap: TUISwap;
    FProgress: TUIProgressBar;
    FPalette: TUICommandPalette;
    FAssistant: TUIAssistant;
    FPages: array[TPage] of TPanel;
    FContent: TPanel;
    FPage: TPage;
    // Issues
    FAlert: TUIAlert;
    FChips: array[TItemFilter] of TUIFilterChip;
    FTags: TTags;
    FTagBar: TPanel;
    FTagChips: TArray<TUIFilterChip>;   // um por tag, na ordem de FTags
    FTagHint: TUILabel;
    FTagMenu: TUIContextMenu;           // submenu "Tag": gerenciar + uma linha por tag
    FActionMenu: TUIContextMenu;        // submenu "Ações": escrita no Jira/GitHub
    FItemsList: TUIVirtualList;
    FItemsEmpty: TUIEmptyState;
    FSkeleton: TPanel;
    FItemMenu: TUIContextMenu;
    FDetail: TDetailPanel;
    // Outras visões
    FDashboard: TDashboardView;
    FDrill: TDrill;                 // filtro vindo de um card do Dashboard
    FDrillChip: TUIFilterChip;      // mostra o FDrill; clicar remove
    FAutostartToggle: TUIToggle;
    FPollMinutes: TUINumberInput;
    FThemeSelect: TUISelect;
    FNotifyStyle: TUISelect;
    FSettingsScroll: TUIScrollArea;
    FSettingsColumn: TPanel;
    FNotifySeconds: TUINumberInput;
    FAccountsList: TUIVirtualList;
    FAccountsEmpty: TUIEmptyState;
    FApiKey: TUIInput;
    // Estado
    FAccounts: TArray<TAccount>;
    FAccountErrors: TDictionary<Integer, string>;
    FAll: TItems;
    FShown: TItems;
    FGroupChip: TUIFilterChip;      // agrupar a lista por repositório/projeto
    FCollapsed: TDictionary<string, Boolean>;  // grupos recolhidos
    FShownTone: TArray<Integer>;
    FShownBadges: TArray<TBadges>;
    FShownTag: TArray<string>;
    FManual: TDictionary<string, Boolean>;
    FTimer: TTimer;
    FClock: TTimer;
    FNextPoll: TDateTime;
    FLastPoll: TDateTime;
    FPolling: Boolean;
    FPollAll: Boolean;              // próxima busca ignora o intervalo de cada conta
    FWinAnim: TUIAnimation;         // abrir/fechar a janela: opacidade + 12 px
    FWinTop: Integer;               // Top de repouso durante a animação
    FWinClosing: Boolean;
    FToastSeq: Integer;
    FToastUrls: TDictionary<string, string>;
    FLastUrl: string;
    FUnread: Integer;
    FOverdue: Boolean;
    FDueSoon: Boolean;
    FNewsUntil: TDateTime;          // até quando o mascote comemora novidade
    FMascotFile: string;
    FApplyingSize: Boolean;
    FUndoAccount: Integer;
    FUndoKey: string;
    // Montagem
    procedure BuildTray;
    procedure BuildShell;
    procedure BuildItemsPage;
    procedure BuildAccountsPage;
    procedure BuildSettingsPage;
    procedure BuildAssistant;
    function NewPanel(AParent: TWinControl; AAlign: TAlign; AHeight: Integer = 0): TPanel;
    function NewList(AParent: TWinControl; ARowHeight: Integer): TUIVirtualList;
    procedure ApplyThemeColors;
    procedure ApplyCompactSize;
    // Navegação
    procedure ShowPage(APage: TPage);
    procedure TabChange(Sender: TObject; AIndex: Integer);
    procedure LoadAiSettings;
    procedure AiSettingChange(Sender: TObject);
    procedure AiAutoChange(Sender: TObject);
    procedure RegisterAiTools;
    procedure ToolItem(const AArgs: TJSONObject; out AItem: TItem; out AAccount: TAccount);
    function FindItem(const AKey: string; out AItem: TItem; out AAccount: TAccount): Boolean;
    function BuildAiContext: string;
    procedure ExplainCiFailure(const AItem: TItem);
    procedure RunAutoAi;
    procedure AiListModelsClick(Sender: TObject);
    procedure AiModelPicked(Sender: TObject; const AID: string);
    procedure UpdateAiUsage;
    procedure RefreshUsdBrl;
    procedure UpdateMascotMood;
    procedure DetailChanged(Sender: TObject);
    procedure SetDetailVisible(AShow: Boolean);
    procedure FlashChanges(const AKeys: TArray<string>);
    procedure AccountCardClick(Sender: TObject);
    procedure ItemsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure CheckSchedules;
    procedure CheckForUpdate(AManual: Boolean);
    procedure StartUpdate(AShow: Boolean);
    procedure UpdateMenuClick(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    function InQuietHours: Boolean;
    function KeyOf(const AItem: TItem): string;
    procedure AccountMenuClick(Sender: TObject; const AID: string);
    procedure AccountBtnClick(Sender: TObject);
    procedure RebuildAccountMenu;
    function InFilter(AAccountId: Integer): Boolean;
    function ItemInView(const AItem: TItem): Boolean;
    procedure RebuildRepoMenu;
    procedure RepoBtnClick(Sender: TObject);
    procedure RepoMenuClick(Sender: TObject; const AID: string);
    procedure SetRepoFilter(const ARepo: string);
    procedure ReloadTags;
    function FilteredItems: TItems;
    procedure PlaceAssistant;
    procedure ClipAssistant;
    procedure SettingsResize(Sender: TObject);
    procedure TestNotifyClick(Sender: TObject);
    procedure GeneralSettingChange(Sender: TObject);
    function PollIntervalMs: Integer;
    procedure RebuildPalette;
    procedure PaletteSelect(Sender: TObject; const AID: string);
    // Dados na tela
    procedure ReloadAccounts;
    procedure LoadItems;
    procedure ApplyFilters;
    procedure UpdateViews;
    procedure UpdateHeader;
    procedure UpdateBadges;
    procedure UpdateTrayIcon;
    procedure UpdateAssistantContext;
    function AccountById(AId: Integer; out AAccount: TAccount): Boolean;
    function IsManual(const AItem: TItem): Boolean;
    function SelectedItem(out AItem: TItem): Boolean;
    procedure OpenDetail(const AItem: TItem);
    // Eventos
    procedure FilterChanged(Sender: TObject);
    procedure RegroupShown;
    procedure ClearFiltersClick(Sender: TObject);
    function IsGroupRow(AIndex: Integer): Boolean;
    procedure DrawGroupRow(AIndex: Integer; const ACanvas: ISkCanvas; const ARowRect: TRectF);
    procedure RebuildTagChips;
    procedure TagMenuClick(Sender: TObject; const AID: string);
    procedure FillTagMenu(const AItem: TItem);
    function NewRowLabel(AParent: TWinControl; const ACaption: string): TUILabel;
    procedure ItemsDraw(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem;
      const ACanvas: ISkCanvas; const ARowRect: TRectF);
    procedure ItemsClick(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem);
    procedure ItemsDblClick(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem);
    procedure ItemsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ItemMenuClick(Sender: TObject; const AID: string);
    procedure ViewOpenItem(Sender: TObject; const AItem: TItem);
    procedure DashboardDrill(Sender: TObject; const ADrill: TDrill);
    procedure DrillChipToggle(Sender: TObject);
    function DrillPass(const AItem: TItem): Boolean;
    procedure NotifyOpenDetail(const AKey: string; AAccountId: Integer);
    procedure DetailClose(Sender: TObject);
    procedure CopyKey(const AItem: TItem);
    procedure RunAction(const AItem: TItem; const ADone: string; const AWork: TProc<TAccount, string>);
    procedure FillActionMenu(const AItem: TItem);
    procedure Unwatch(const AItem: TItem);
    procedure UndoUnwatch(Sender: TObject);
    procedure WatchKey(const AText: string);
    procedure BuildFooter;
    procedure FooterClick(Sender: TObject);
    procedure FormKeyDownEsc;
    procedure NewAccountClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure SaveApiKeyClick(Sender: TObject);
    procedure AlertDismiss(Sender: TObject);
    procedure AutostartClick(Sender: TObject);
    procedure ThemeSwapToggle(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    // Busca e avisos
    procedure Poll(AManual: Boolean);
    procedure TimerTick(Sender: TObject);
    procedure ClockTick(Sender: TObject);
    procedure ToastClicked(Sender: TObject; ANotification: TNotification);
    procedure BalloonClick(Sender: TObject);
    // Janela e tray
    procedure TrayDblClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure AnimateWindowTo(AShow: Boolean);
    procedure ThemeChanged(Sender: TObject; AMode: TUIThemeMode);
  protected
    procedure CreateWnd; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notify(const ATitle, ABody: string; const AUrl: string = '';
      ATone: TUISemanticTone = stInfo; const AKey: string = ''; AAccountId: Integer = 0);
  end;

var
  MainForm: TMainForm;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.StrUtils,
  System.Math,
  System.DateUtils,
  System.Threading,
  System.Generics.Defaults,
  System.Win.Registry,
  UI.Assistant.Tools,
  Vcl.Clipbrd,
  UI.Fonts,
  UI.Painter,
  UI.Painter.Vcl,
  UI.Toast,
  UI.Card,
  UI.NumberTween,
  UI.Avatar,
  UI.PageTransition.Vcl,
  UI.Icons.Heroicons,
  Vigia.Store,
  Vigia.Secrets,
  Vigia.Providers,
  Vigia.Diff,
  Vigia.TrayIcon,
  Vigia.UI.Account,
  Vigia.UI.Status,
  Vigia.UI.Tags,
  Vigia.UI.Notify;

const
  // ponytail: intervalo fixo e sem backoff; virar config por conta se o rate limit apertar.
  DefaultPollMinutes = 5;
  DefaultNotifySeconds = 8;
  FirstPollMs = 3 * 1000;
  MaxToastsPerPoll = 4;
  RunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';
  AssistantSecret = 'Vigia:anthropic';
  AssistantModel = 'claude-sonnet-5-5';
  DetailWidth = 380;
  FilterNames: array[TItemFilter] of string = ('Comigo', 'Atrasadas', 'Review', 'Manuais', 'Impedidas', 'Meus PRs', 'Sprint');
  FilterTones: array[TItemFilter] of TUIBadgeTone = (btPrimary, btError, btInfo, btWarning, btError, btSuccess, btInfo);
  PageTitles: array[TPage] of string = ('Dashboard', 'Issues', 'Contas', 'Configurações');

type
  // FirstVisible/RowRect/OnMouseDown são protected.
  TListAccess = class(TUIVirtualList);
  // OnClick é protected no TControl.
  TClickAccess = class(TControl);

  { Ctrl+K: texto com cara de chave (PROJ-123, dono/repo#12) vira "Acompanhar". }
  TWatchProvider = class(TInterfacedObject, IUICommandSearchProvider)
    function GroupName: string;
    function GroupIconSvg: string;
    function Search(const AQuery: string; AMaxResults: Integer): TUISearchHits;
  end;

function TWatchProvider.GroupName: string;
begin
  Result := 'Acompanhar';
end;

function TWatchProvider.GroupIconSvg: string;
begin
  Result := HeroIcon('squares-plus');
end;

function TWatchProvider.Search(const AQuery: string; AMaxResults: Integer): TUISearchHits;
var
  Key: string;
  IsGitHub: Boolean;
  H: TUISearchHit;
begin
  Result := nil;
  Key := NormalizeManualKey(AQuery, IsGitHub);
  if Key = '' then
    Exit;
  H := Default(TUISearchHit);
  H.ID := 'watch:' + Key;
  H.Title := 'Acompanhar ' + Key;
  H.Subtitle := IfThen(IsGitHub, 'Issue/PR do GitHub', 'Issue do Jira') + ' · entra na lista mesmo sem ser sua';
  H.IconSvg := HeroIcon('squares-plus');
  H.Score := 1000;
  Result := [H];
end;

type
  TPollResult = record
    Account: TAccount;
    ManualKeys: TArray<string>;
    Items: TItems;
    Me: TIdentity;
    Error: string;
  end;

var
  ExitRequested: Boolean;

procedure OpenUrl(const AUrl: string);
begin
  if AUrl <> '' then
    ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
end;

function Sp(AValue: Single): Integer;
begin
  Result := Round(AValue);
end;

function AutostartEnabled: Boolean;
var
  R: TRegistry;
begin
  R := TRegistry.Create(KEY_READ);
  try
    R.RootKey := HKEY_CURRENT_USER;
    Result := R.OpenKeyReadOnly(RunKey) and R.ValueExists('Vigia');
  finally
    R.Free;
  end;
end;

procedure SetAutostart(AOn: Boolean);
var
  R: TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(RunKey, True) then
      if AOn then
        R.WriteString('Vigia', '"' + ParamStr(0) + '"')
      else if R.ValueExists('Vigia') then
        R.DeleteValue('Vigia');
  finally
    R.Free;
  end;
end;

{ Horário 'hh:nn' guardado nas preferências. }
function TimeSetting(const AName, ADefault: string): TDateTime;
begin
  Result := StrToTimeDef(Store.GetSetting(AName, ADefault), StrToTime(ADefault));
end;

function IsOverdue(const AItem: TItem): Boolean;
begin
  Result := (AItem.DueDate > 0) and (DateOf(AItem.DueDate) < Date);
end;

{ ── Criação ─────────────────────────────────────────────────────────────── }

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Vigia ' + AppVersion;
  ClientWidth := ScaleValue(1040);
  ClientHeight := ScaleValue(720);
  Constraints.MinWidth := ScaleValue(720);
  Constraints.MinHeight := ScaleValue(480);
  Position := poScreenCenter;
  DoubleBuffered := True;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnCloseQuery := FormCloseQuery;
  AlphaBlend := True;
  AlphaBlendValue := 255;

  // Tema escolhido no botão vale por usuário; sem escolha, segue o Windows.
  case IndexText(Store.GetSetting('theme'), ['light', 'dark']) of
    0: UITheme.Mode := tmLight;
    1: UITheme.Mode := tmDark;
  end;
  ApplyCompactSize;
  RegisterVigiaAiProvider;
  FAccountFilter := StrToIntDef(Store.GetSetting('account_filter'), 0);

  FToastUrls := TDictionary<string, string>.Create;
  FManual := TDictionary<string, Boolean>.Create;
  FAccountErrors := TDictionary<Integer, string>.Create;
  FFlashKeys := TDictionary<string, Boolean>.Create;
  FNewKeys := TDictionary<string, Boolean>.Create;
  FMuted := TDictionary<string, Boolean>.Create;
  FTransition := TUIPageTransition.Create;
  FTransition.Style := ttSlide;
  FNotifier := TNotificationCenter.Create(Self);
  FNotifier.OnReceiveLocalNotification := ToastClicked;
  TUIToastManager.Position := tpBottomRight;
  TNotifyManager.OnOpenDetail := NotifyOpenDetail;

  BuildTray;
  BuildShell;
  BuildItemsPage;
  BuildAccountsPage;
  BuildSettingsPage;
  BuildAssistant;
  ApplyThemeColors;
  ReloadAccounts;
  LoadItems;
  ShowPage(pgDashboard);

  UITheme.AddChangeListener(ThemeChanged);

  FTimer := TTimer.Create(Self);
  FTimer.Interval := FirstPollMs;
  FPollAll := True;
  FTimer.OnTimer := TimerTick;
  FNextPoll := Now + FirstPollMs / MSecsPerDay;
  FTimer.Enabled := True;

  FClock := TTimer.Create(Self);
  FClock.Interval := 1000;
  FClock.OnTimer := ClockTick;
  FClock.Enabled := True;
end;

destructor TMainForm.Destroy;
begin
  UITheme.RemoveChangeListener(ThemeChanged);
  FToastUrls.Free;
  FManual.Free;
  FAccountErrors.Free;
  FFlashKeys.Free;
  FNewKeys.Free;
  FMuted.Free;
  FTransition.Free;
  FWinAnim.Free;
  FDetailAnim.Free;
  FFlashAnim.Free;
  inherited;
end;

var
  WM_VIGIA_SHOW: Cardinal;

procedure TMainForm.WndProc(var Message: TMessage);
begin
  if (WM_VIGIA_SHOW <> 0) and (Message.Msg = WM_VIGIA_SHOW) then
    MenuOpenClick(nil)
  else
    inherited;
end;

procedure TMainForm.CreateWnd;
begin
  inherited;
  ApplyTitleBarTheme(Self);
end;

function TMainForm.NewPanel(AParent: TWinControl; AAlign: TAlign; AHeight: Integer): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.BevelOuter := bvNone;
  Result.ParentBackground := False;
  Result.DoubleBuffered := True;
  if AHeight > 0 then
    Result.Height := ScaleValue(AHeight);
  Result.Align := AAlign;
  Result.Parent := AParent;
end;

function TMainForm.NewList(AParent: TWinControl; ARowHeight: Integer): TUIVirtualList;
begin
  Result := TUIVirtualList.Create(Self);
  Result.RowHeight := ARowHeight;
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(Sp(UITheme.Tokens.Spacing.S2), 0, Sp(UITheme.Tokens.Spacing.S2),
    Sp(UITheme.Tokens.Spacing.S2));
  Result.Align := alClient;
  Result.Parent := AParent;
end;

{ Os TPanel VCL não ouvem o tema; a cor vem daqui. }
procedure TMainForm.ApplyThemeColors;

  procedure Paint(AControl: TWinControl);
  var
    I: Integer;
  begin
    if (AControl is TPanel) and (AControl.Tag = 1) then
      TPanel(AControl).Color := UIAlphaToVclColor(UITheme.Tokens.Color.Border)
    else if (AControl is TPanel) and not TPanel(AControl).ParentBackground then
      TPanel(AControl).Color := UIThemeVclBackground;
    for I := 0 to AControl.ControlCount - 1 do
      if AControl.Controls[I] is TWinControl then
        Paint(TWinControl(AControl.Controls[I]));
  end;

begin
  Color := UIThemeVclBackground;
  Paint(Self);
  ApplyTitleBarTheme(Self);
end;

{ Campos, seleção e botões com 36 px (o preset da suíte é 50). A troca de tema
  reconstrói os tokens a partir do preset, então reaplica depois de cada troca. }
procedure TMainForm.ApplyCompactSize;
const
  FieldPx = 36;
  SelectorPx = 22;
begin
  if FApplyingSize or (UITheme.Tokens.Size.FieldBase = FieldPx) then
    Exit;
  FApplyingSize := True;
  try
    UITheme.SetCustomSize(FieldPx, SelectorPx, 1);
  finally
    FApplyingSize := False;
  end;
end;

procedure TMainForm.BuildTray;

  function AddItem(const ACaption: string; AOnClick: TNotifyEvent): TMenuItem;
  begin
    Result := TMenuItem.Create(FTrayMenu);
    Result.Caption := ACaption;
    Result.OnClick := AOnClick;
    FTrayMenu.Items.Add(Result);
  end;

begin
  FTrayMenu := TPopupMenu.Create(Self);
  AddItem('Abrir', MenuOpenClick).Default := True;
  AddItem('Atualizar agora', RefreshClick);
  FAutostartItem := AddItem('Iniciar com o Windows', AutostartClick);
  FAutostartItem.Checked := AutostartEnabled;
  FUpdateItem := AddItem('Atualizar o Vigia', UpdateMenuClick);
  FUpdateItem.Visible := False;
  AddItem('-', nil);
  AddItem('Sair', MenuExitClick);

  FTray := TTrayIcon.Create(Self);
  UpdateTrayIcon;
  FTray.Hint := 'Vigia';
  FTray.PopupMenu := FTrayMenu;
  FTray.OnDblClick := TrayDblClick;
  FTray.OnBalloonClick := BalloonClick;
  FTray.Visible := True;
end;

{ Menu lateral + cabeçalho + barra de progresso + uma página por item do menu. }
procedure TMainForm.BuildShell;
var
  S: TUISpacingTokens;
  Bar: TPanel;
  P: TPage;
begin
  S := UITheme.Tokens.Spacing;

  FContent := NewPanel(Self, alClient);

  Bar := NewPanel(FContent, alTop, 60);
  Bar.Padding.SetBounds(0, 0, Sp(S.S4), 0);

  // Direita: buscar (Ctrl+K), conta, tema. Esquerda: estado + contagem.
  FThemeSwap := TUISwap.Create(Self);
  FThemeSwap.SvgOff := HeroIcon(hiSun);
  FThemeSwap.SvgOn := HeroIcon(hiMoon);
  FThemeSwap.SwapType := stRotate;
  FThemeSwap.Size := 36;
  FThemeSwap.Checked := UITheme.IsDark;
  FThemeSwap.Hint := 'Tema claro/escuro';
  FThemeSwap.TabStop := False;  // o anel de foco pontilhado parecia falha no desenho
  FThemeSwap.ShowHint := True;
  FThemeSwap.OnToggle := ThemeSwapToggle;
  FThemeSwap.AlignWithMargins := True;
  FThemeSwap.Margins.SetBounds(Sp(S.S2), 12, 0, 12);
  FThemeSwap.Left := 3000;  // alRight: maior Left fica mais à direita
  FThemeSwap.Align := alRight;
  FThemeSwap.Parent := Bar;

  // Seletor de conta discreto: botão fantasma + menu da suíte.
  FAccountBtn := TUIButton.Create(Self);
  FAccountBtn.Variant := bvGhost;
  // Largura fixa: com AutoWidth a troca de conta mudava a largura e o VCL
  // reordenava os controles alRight do cabeçalho.
  FAccountBtn.Width := ScaleValue(200);
  FAccountBtn.Hint := 'Conta exibida em todas as telas e no Ctrl+K';
  FAccountBtn.ShowHint := True;
  FAccountBtn.OnClick := AccountBtnClick;
  FAccountBtn.AlignWithMargins := True;
  FAccountBtn.Margins.SetBounds(Sp(S.S2), 12, 0, 12);
  FAccountBtn.Left := 2000;
  FAccountBtn.Align := alRight;
  FAccountBtn.Parent := Bar;
  FRepoBtn := TUIButton.Create(Self);
  FRepoBtn.Variant := bvGhost;
  FRepoBtn.Width := ScaleValue(240);
  FRepoBtn.Hint := 'Repositório exibido em Issues e no Dashboard';
  FRepoBtn.ShowHint := True;
  FRepoBtn.OnClick := RepoBtnClick;
  FRepoBtn.AlignWithMargins := True;
  FRepoBtn.Margins.SetBounds(Sp(S.S2), 12, 0, 12);
  FRepoBtn.Left := 1500;
  FRepoBtn.Align := alRight;
  FRepoBtn.Visible := False;
  FRepoBtn.Parent := Bar;
  FRepoMenu := TUIDropdown.Create(Self);
  FRepoMenu.AnchorControl := FRepoBtn;
  FRepoMenu.AnchorPos := dapBottomRight;
  FRepoMenu.MaxHeight := 420;
  FRepoMenu.PopupWidth := 360;
  FRepoMenu.OnItemClick := RepoMenuClick;
  FRepoFilter := Store.GetSetting('repo_filter');
  FAccountMenu := TUIDropdown.Create(Self);
  FAccountMenu.AnchorControl := FAccountBtn;
  FAccountMenu.AnchorPos := dapBottomRight;
  FAccountMenu.OnItemClick := AccountMenuClick;

  // Anel fino que esvazia até a próxima busca, com a bolinha de estado dentro.
  FNextRing := TUIRadialProgress.Create(Self);
  FNextRing.RingSize := 22;
  FNextRing.StrokeWidth := 2;
  FNextRing.ShowPercent := False;
  FNextRing.AnimateValue := False;
  FNextRing.Max := 100;
  FNextRing.Width := ScaleValue(26);
  FNextRing.AlignWithMargins := True;
  FNextRing.Margins.SetBounds(Sp(S.S4), 17, Sp(S.S2), 17);
  FNextRing.Align := alLeft;
  FNextRing.Parent := Bar;
  FStatusDot := TUIStatus.Create(Self);
  FStatusDot.Status := sdOnline;
  FStatusDot.Size := sdsSM;
  FStatusDot.Parent := FNextRing;
  FStatusDot.SetBounds(ScaleValue(7), ScaleValue(7), ScaleValue(12), ScaleValue(12));

  // Detalhe (itens, última e próxima busca) fica na dica do anel.
  FNextRing.ShowHint := True;

  FTabs := TUITabs.Create(Self);
  FTabs.AlignWithMargins := True;
  FTabs.Margins.SetBounds(Sp(S.S4), 0, Sp(S.S4), 0);
  FTabs.Parent := FContent;
  FTabs.Top := Bar.Top + Bar.Height + 1;
  FTabs.Align := alTop;
  UpdateBadges;

  // Linha fina animada só enquanto busca.
  FProgress := TUIProgressBar.Create(Self);
  FProgress.Indeterminate := True;
  FProgress.TrackHeight := 3;
  FProgress.Height := 3;
  FProgress.Visible := False;
  FProgress.Parent := FContent;
  FProgress.Top := FTabs.Top + FTabs.Height + 1;
  FProgress.Align := alTop;

  for P := Low(TPage) to High(TPage) do
  begin
    FPages[P] := NewPanel(FContent, alClient);
    FPages[P].Visible := False;
  end;
  BuildFooter;
  FFooter.Height := ScaleValue(43);
  FProgress.Parent := FFooter;
  FProgress.Align := alBottom;

  FDashboard := TDashboardView.Create(Self);
  FDashboard.OnOpenItem := ViewOpenItem;
  FDashboard.OnDrill := DashboardDrill;
  FDashboard.OnAddAccount := NewAccountClick;
  FDashboard.Parent := FPages[pgDashboard];

  FPalette := TUICommandPalette.Create(Self);
  FPalette.Shortcut := 'Ctrl+K';
  FPalette.Placeholder := 'Buscar issue ou comando...';
  FPalette.OnItemSelect := PaletteSelect;
  FPalette.AddProvider(TWatchProvider.Create);
end;

procedure TMainForm.BuildItemsPage;
var
  S: TUISpacingTokens;
  Page, Bar: TPanel;
  F: TItemFilter;
  I: Integer;
  Sk: TUISkeletonLoader;
  SkRow: TPanel;
begin
  S := UITheme.Tokens.Spacing;
  Page := FPages[pgIssues];

  FDetail := TDetailPanel.Create(Self);
  FDetail.Width := ScaleValue(DetailWidth);
  FDetail.Visible := False;
  FDetail.OnClose := DetailClose;
  FDetail.OnChanged := DetailChanged;
  FDetail.Align := alRight;
  FDetail.Parent := Page;

  FAlert := TUIAlert.Create(Self);
  FAlert.Tone := atError;
  FAlert.Style_ := asSoft;
  FAlert.Dismissible := True;
  FAlert.OnDismiss := AlertDismiss;
  FAlert.Visible := False;
  FAlert.AlignWithMargins := True;
  FAlert.Margins.SetBounds(Sp(S.S4), Sp(S.S3), Sp(S.S4), 0);
  FAlert.Align := alTop;
  FAlert.Parent := Page;

  // Filtros rápidos (situação) e tags (projeto do usuário), cada um na sua linha.
  Bar := NewPanel(Page, alTop, 44);
  Bar.Top := Page.ControlCount * 1000;
  Bar.Padding.SetBounds(Sp(S.S4), Sp(S.S2), Sp(S.S4), Sp(S.S1));
  NewRowLabel(Bar, 'Filtros');
  for F := Low(TItemFilter) to High(TItemFilter) do
  begin
    FChips[F] := TUIFilterChip.Create(Self);
    FChips[F].Caption := FilterNames[F];
    FChips[F].Count := 0;
    FChips[F].Tone := FilterTones[F];
    FChips[F].OnToggle := FilterChanged;
    FChips[F].Left := (Ord(F) + 1) * 1000;
    FChips[F].AlignWithMargins := True;
    FChips[F].Margins.SetBounds(0, 0, Sp(S.S2), 0);
    FChips[F].Align := alLeft;
    FChips[F].Parent := Bar;
  end;
  FGroupChip := TUIFilterChip.Create(Self);
  FGroupChip.Caption := 'Agrupar';
  FGroupChip.Hint := 'Agrupa a lista por repositório (GitHub) ou projeto (Jira)';
  FGroupChip.ShowHint := True;
  FGroupChip.Active := Store.GetSetting('group_list') = '1';
  FGroupChip.OnToggle := FilterChanged;
  FGroupChip.AlignWithMargins := True;
  FGroupChip.Margins.SetBounds(Sp(S.S4), 0, 0, 0);
  FGroupChip.Left := 90000;
  FGroupChip.Align := alLeft;
  FGroupChip.Parent := Bar;
  FCollapsed := TDictionary<string, Boolean>.Create;
  FDrillChip := TUIFilterChip.Create(Self);
  FDrillChip.Tone := btPrimary;
  FDrillChip.Active := True;
  FDrillChip.Visible := False;
  FDrillChip.OnToggle := DrillChipToggle;
  FDrillChip.Left := 100000;
  FDrillChip.Align := alLeft;
  FDrillChip.Parent := Bar;

  FTagBar := NewPanel(Page, alTop, 40);
  FTagBar.Top := Page.ControlCount * 1000;
  FTagBar.Padding.SetBounds(Sp(S.S4), 0, Sp(S.S4), Sp(S.S1));
  NewRowLabel(FTagBar, 'Tags');
  FTagHint := TUILabel.Create(Self);
  FTagHint.Caption := 'Botão direito numa issue › Tag › Gerenciar para criar (ex.: #Bug, #Feature)';
  FTagHint.Variant := lvMuted;
  FTagHint.AutoSize := False;
  FTagHint.Width := ScaleValue(600);
  FTagHint.Left := 900000;
  FTagHint.Align := alLeft;
  FTagHint.Parent := FTagBar;
  FTagMenu := TUIContextMenu.Create(Self);
  FTagMenu.OnItemClick := TagMenuClick;
  FActionMenu := TUIContextMenu.Create(Self);
  FActionMenu.OnItemClick := TagMenuClick;

  FItemsList := NewList(Page, 76);
  FItemsList.OnCustomDraw := ItemsDraw;
  FItemsList.OnItemClick := ItemsClick;
  FItemsList.OnItemDblClick := ItemsDblClick;
  TListAccess(FItemsList).OnMouseDown := ItemsMouseDown;
  TListAccess(FItemsList).OnMouseMove := ItemsMouseMove;
  FItemsList.ShowHint := True;

  // Menu da suíte; os itens são montados no botão direito (o "parar" depende da linha).
  FItemMenu := TUIContextMenu.Create(Self);
  FItemMenu.OnItemClick := ItemMenuClick;
  FItemMenu.AttachTo(FItemsList);

  FItemsEmpty := TUIEmptyState.Create(Self);
  FItemsEmpty.Visible := False;
  FItemsEmpty.Align := alClient;
  FItemsEmpty.Parent := Page;

  FSkeleton := NewPanel(Page, alClient);
  FSkeleton.Padding.SetBounds(Sp(S.S4), Sp(S.S2), Sp(S.S4), 0);
  FSkeleton.Visible := False;
  for I := 1 to 6 do
  begin
    // Mesmo desenho da linha real: chave curta, título longo, dois selos.
    SkRow := NewPanel(FSkeleton, alNone, 76);
    SkRow.Top := I * 1000;
    SkRow.Align := alTop;
    Sk := TUISkeletonLoader.Create(Self);
    Sk.Shape := ssText;
    Sk.SetBounds(ScaleValue(14), ScaleValue(10), ScaleValue(110), ScaleValue(12));
    Sk.Parent := SkRow;
    Sk := TUISkeletonLoader.Create(Self);
    Sk.Shape := ssText;
    Sk.SetBounds(ScaleValue(14), ScaleValue(30), ScaleValue(380 - I * 25), ScaleValue(14));
    Sk.Parent := SkRow;
    Sk := TUISkeletonLoader.Create(Self);
    Sk.SetBounds(ScaleValue(14), ScaleValue(52), ScaleValue(80), ScaleValue(16));
    Sk.Parent := SkRow;
    Sk := TUISkeletonLoader.Create(Self);
    Sk.SetBounds(ScaleValue(100), ScaleValue(52), ScaleValue(64), ScaleValue(16));
    Sk.Parent := SkRow;
  end;
end;

procedure TMainForm.BuildAccountsPage;
var
  S: TUISpacingTokens;
  Page, Bar: TPanel;
  Btn: TUIButton;
begin
  S := UITheme.Tokens.Spacing;
  Page := FPages[pgAccounts];

  Bar := NewPanel(Page, alTop, 60);
  Bar.Padding.SetBounds(Sp(S.S4), Sp(S.S3), Sp(S.S4), Sp(S.S2));
  Btn := TUIButton.Create(Self);
  Btn.Caption := 'Nova conta';
  Btn.AutoWidth := True;
  Btn.OnClick := NewAccountClick;
  Btn.Align := alRight;
  Btn.Parent := Bar;

  FAccountsList := NewList(Page, 64);  // ponytail: fica escondida; cartões no lugar
  FAccountsList.Visible := False;
  FAccountsBox := TUIScrollArea.Create(Self);
  FAccountsBox.Align := alClient;
  FAccountsBox.Parent := Page;

  FAccountsEmpty := TUIEmptyState.Create(Self);
  FAccountsEmpty.Title := 'Nenhuma conta ainda';
  FAccountsEmpty.Description := 'Adicione uma conta do GitHub ou do Jira para o Vigia começar a acompanhar.';
  FAccountsEmpty.ActionLabel := 'Nova conta';
  FAccountsEmpty.OnAction := NewAccountClick;
  FAccountsEmpty.Visible := False;
  FAccountsEmpty.Align := alClient;
  FAccountsEmpty.Parent := Page;
end;

{ Configurações em seções (cartões). Cada linha: título e descrição à
  esquerda, controle à direita, com a mesma altura de 36 px dos campos. }
procedure TMainForm.BuildSettingsPage;
const
  ColumnW = 760;
  RowH = 80;     // campos têm até 40 px; 20 de respiro em cima e embaixo
  FieldH = 40;
var
  S: TUISpacingTokens;
  Page, Column: TPanel;
  Card: TUICard;

  function NewSection(const ATitle: string; ARows: Integer): TUICard;
  var
    Lbl: TUILabel;
  begin
    Result := TUICard.Create(Self);
    Result.Variant := cvOutlined;
    Result.CardPad := cpNone;
    Result.Padding.SetBounds(Sp(S.S4), Sp(S.S3), Sp(S.S4), Sp(S.S2));
    Result.Height := ScaleValue(44 + ARows * RowH + 8);
    Result.AlignWithMargins := True;
    Result.Margins.SetBounds(0, Sp(S.S4), 0, 0);
    Result.Parent := Column;
    Result.Top := Column.ControlCount * 1000;
    Result.Align := alTop;
    Lbl := TUILabel.Create(Self);
    Lbl.Caption := ATitle;
    Lbl.Bold := True;
    Lbl.FontSize := 15;
    Lbl.AutoSize := False;
    Lbl.Height := ScaleValue(28);
    Lbl.Parent := Result;
    Lbl.Top := 0;
    Lbl.Align := alTop;
  end;

  { Linha com título/descrição; devolve o painel da direita para o controle. }
  function NewRow(ACard: TUICard; const ATitle, ADesc: string; AControlW: Integer): TPanel;
  var
    Row, Text, Line: TPanel;
    Lbl: TUILabel;
    VPad: Integer;
  begin
    Row := NewPanel(ACard, alNone, RowH);
    Row.Top := ACard.ControlCount * 1000;
    Row.Align := alTop;
    Line := NewPanel(Row, alTop, 1);
    Line.Tag := 1;  // divisória: cor de borda, não de fundo
    Line.Color := UIAlphaToVclColor(UITheme.Tokens.Color.Border);
    VPad := (ScaleValue(RowH) - ScaleValue(FieldH)) div 2;
    Result := NewPanel(Row, alRight);
    Result.Width := ScaleValue(AControlW);
    Result.Padding.SetBounds(0, VPad, 0, VPad);
    Text := NewPanel(Row, alClient);
    Text.Padding.SetBounds(0, Sp(S.S3), Sp(S.S4), 0);
    Lbl := TUILabel.Create(Self);
    Lbl.Caption := ATitle;
    Lbl.AutoSize := False;
    Lbl.Height := ScaleValue(20);
    Lbl.Parent := Text;
    Lbl.Top := 0;
    Lbl.Align := alTop;
    Lbl := TUILabel.Create(Self);
    Lbl.Caption := ADesc;
    Lbl.Variant := lvMuted;
    Lbl.AutoSize := False;
    Lbl.WordWrap := True;
    Lbl.Parent := Text;
    Lbl.Top := 1000;
    Lbl.Align := alClient;
  end;

var
  Host, Row: TPanel;
  Btn: TUIButton;
  AK: TAiProviderKind;
  UK: Integer;
begin
  S := UITheme.Tokens.Spacing;
  Page := FPages[pgSettings];
  // Coluna centralizada de largura fixa (linhas largas demais cansam a leitura),
  // dentro de uma área de rolagem.
  FSettingsScroll := TUIScrollArea.Create(Self);
  FSettingsScroll.Align := alClient;
  FSettingsScroll.AutoHideScrollbar := False;  // mostra onde a tela está mesmo parada
  FSettingsScroll.Parent := Page;
  Column := NewPanel(FSettingsScroll.InnerPanel, alNone);
  Column.Width := ScaleValue(ColumnW);
  Column.Height := ScaleValue(2000);
  FSettingsColumn := Column;
  Page.OnResize := SettingsResize;

  Card := NewSection('Geral', 4);
  Host := NewRow(Card, 'Iniciar com o Windows',
    'Abre o Vigia na bandeja quando você entra no Windows. Vale só para este usuário.', 60);
  FAutostartToggle := TUIToggle.Create(Self);
  FAutostartToggle.Checked := AutostartEnabled;
  FAutostartToggle.OnChange := GeneralSettingChange;
  FAutostartToggle.Align := alClient;
  FAutostartToggle.Parent := Host;

  Host := NewRow(Card, 'Buscar a cada', 'Intervalo entre as consultas ao GitHub e ao Jira.', 150);
  FPollMinutes := TUINumberInput.Create(Self);
  FPollMinutes.SuffixText := 'min';
  FPollMinutes.Min := 1;
  FPollMinutes.Max := 120;
  FPollMinutes.Value := StrToIntDef(Store.GetSetting('poll_minutes'), DefaultPollMinutes);
  FPollMinutes.OnChange := GeneralSettingChange;
  FPollMinutes.Align := alClient;
  FPollMinutes.Parent := Host;

  Host := NewRow(Card, 'Tema', 'Seguir o Windows ou fixar claro ou escuro.', 220);
  FThemeSelect := TUISelect.Create(Self);
  FThemeSelect.Items.Add('Seguir o Windows');
  FThemeSelect.Items.Add('Claro');
  FThemeSelect.Items.Add('Escuro');
  FThemeSelect.ItemIndex := IndexText(Store.GetSetting('theme'), ['', 'light', 'dark']);
  FThemeSelect.OnChange := GeneralSettingChange;
  FThemeSelect.Align := alClient;
  FThemeSelect.Parent := Host;

  Host := NewRow(Card, 'Atualizações', 'Versão ' + AppVersion + '. Procura release nova uma vez por dia ' +
    '(só na versão instalada).', 340);
  FUpdateBtn := TUIButton.Create(Self);
  FUpdateBtn.Caption := 'Procurar agora';
  FUpdateBtn.Variant := bvOutline;
  FUpdateBtn.AutoWidth := True;
  FUpdateBtn.OnClick := UpdateBtnClick;
  FUpdateBtn.AlignWithMargins := True;
  FUpdateBtn.Margins.SetBounds(Sp(S.S2), 0, 0, 0);
  FUpdateBtn.Align := alRight;
  FUpdateBtn.Parent := Host;
  FUpdateMode := TUISelect.Create(Self);
  FUpdateMode.Items.Add('Só avisar');
  FUpdateMode.Items.Add('Instalar sozinho');
  FUpdateMode.Items.Add('Não procurar');
  FUpdateMode.ItemIndex := Max(0, IndexText(Store.GetSetting('update_mode'), ['notify', 'auto', 'off']));
  FUpdateMode.OnChange := GeneralSettingChange;
  FUpdateMode.Align := alClient;
  FUpdateMode.Parent := Host;

  Card := NewSection('Notificações', 5);
  Host := NewRow(Card, 'Estilo do aviso',
    'Popup do Vigia no canto da tela, ou a notificação padrão do Windows.', 220);
  FNotifyStyle := TUISelect.Create(Self);
  FNotifyStyle.Items.Add('Popup do Vigia');
  FNotifyStyle.Items.Add('Windows');
  FNotifyStyle.ItemIndex := IfThen(Store.GetSetting('notify_style', 'vigia') = 'vigia', 0, 1);
  FNotifyStyle.OnChange := GeneralSettingChange;
  FNotifyStyle.Align := alClient;
  FNotifyStyle.Parent := Host;

  Host := NewRow(Card, 'Tempo na tela',
    'Quanto o popup fica visível. Com o mouse em cima ele espera.', 150);
  FNotifySeconds := TUINumberInput.Create(Self);
  FNotifySeconds.SuffixText := 's';
  FNotifySeconds.Min := 3;
  FNotifySeconds.Max := 60;
  FNotifySeconds.Value := StrToIntDef(Store.GetSetting('notify_seconds'), DefaultNotifySeconds);
  FNotifySeconds.OnChange := GeneralSettingChange;
  FNotifySeconds.Align := alClient;
  FNotifySeconds.Parent := Host;

  Host := NewRow(Card, 'Resumo do dia',
    'Um aviso por dia com o que vence, o que está impedido e os comentários novos.', 200);
  FSummaryTime := TUITimePicker.Create(Self);
  FSummaryTime.Hour := HourOf(TimeSetting('summary_time', '09:00'));
  FSummaryTime.Minute := MinuteOf(TimeSetting('summary_time', '09:00'));
  FSummaryTime.OnChange := GeneralSettingChange;
  FSummaryTime.Align := alClient;
  FSummaryTime.Parent := Host;
  FSummaryToggle := TUIToggle.Create(Self);
  FSummaryToggle.Checked := Store.GetSetting('summary_on', '1') = '1';
  FSummaryToggle.OnChange := GeneralSettingChange;
  FSummaryToggle.Width := ScaleValue(60);
  FSummaryToggle.Align := alLeft;
  FSummaryToggle.Parent := Host;

  Host := NewRow(Card, 'Não perturbe',
    'Nesse horário os avisos esperam e chegam juntos quando o silêncio acaba.', 300);
  FDndToggle := TUIToggle.Create(Self);
  FDndToggle.Checked := Store.GetSetting('dnd_on', '0') = '1';
  FDndToggle.OnChange := GeneralSettingChange;
  FDndToggle.Width := ScaleValue(60);
  FDndToggle.Align := alLeft;
  FDndToggle.Parent := Host;
  FDndStart := TUITimePicker.Create(Self);
  FDndStart.Hour := HourOf(TimeSetting('dnd_start', '19:00'));
  FDndStart.Minute := MinuteOf(TimeSetting('dnd_start', '19:00'));
  FDndStart.OnChange := GeneralSettingChange;
  FDndStart.Width := ScaleValue(116);
  FDndStart.Left := 1000;
  FDndStart.Align := alLeft;
  FDndStart.Parent := Host;
  FDndEnd := TUITimePicker.Create(Self);
  FDndEnd.Hour := HourOf(TimeSetting('dnd_end', '08:00'));
  FDndEnd.Minute := MinuteOf(TimeSetting('dnd_end', '08:00'));
  FDndEnd.OnChange := GeneralSettingChange;
  FDndEnd.AlignWithMargins := True;
  FDndEnd.Margins.SetBounds(ScaleValue(8), 0, 0, 0);
  FDndEnd.Left := 2000;
  FDndEnd.Align := alClient;
  FDndEnd.Parent := Host;

  Host := NewRow(Card, 'Testar', 'Mostra um aviso de exemplo com o estilo escolhido.', 150);
  Btn := TUIButton.Create(Self);
  Btn.Caption := 'Mostrar aviso';
  Btn.Variant := bvOutline;
  Btn.OnClick := TestNotifyClick;
  Btn.Align := alClient;
  Btn.Parent := Host;

  Card := NewSection('Assistente de IA', 5);
  Host := NewRow(Card, 'Provedor', 'Anthropic usa o assistente completo da suíte; os outros, a API ' +
    'compatível com OpenAI.', 260);
  FAiProvider := TUISelect.Create(Self);
  for AK := Low(TAiProviderKind) to High(TAiProviderKind) do
    FAiProvider.Items.Add(AiProviderNames[AK]);
  FAiProvider.ItemIndex := Ord(CurrentAiConfig.Kind);
  FAiProvider.OnChange := AiSettingChange;
  FAiProvider.Align := alClient;
  FAiProvider.Parent := Host;

  Host := NewRow(Card, 'Endereço da API', 'Já vem preenchido; troque para um gateway próprio ou Ollama remoto.', 340);
  FAiBaseUrl := TUIInput.Create(Self);
  FAiBaseUrl.ReserveHintSpace := False;
  FAiBaseUrl.OnBlur := AiSettingChange;
  FAiBaseUrl.Align := alClient;
  FAiBaseUrl.Parent := Host;

  Host := NewRow(Card, 'Chave', 'Uma por provedor, no Credential Manager deste usuário.', 340);
  Btn := TUIButton.Create(Self);
  Btn.Caption := 'Salvar';
  Btn.AutoWidth := True;
  Btn.OnClick := SaveApiKeyClick;
  Btn.AlignWithMargins := True;
  Btn.Margins.SetBounds(Sp(S.S2), 0, 0, 0);
  Btn.Align := alRight;
  Btn.Parent := Host;
  FApiKey := TUIInput.Create(Self);
  FApiKey.PasswordChar := '*';
  FApiKey.PasswordToggle := True;
  FApiKey.ReserveHintSpace := False;
  FApiKey.Align := alClient;
  FApiKey.Parent := Host;

  Host := NewRow(Card, 'Modelo', 'Digite ou escolha da lista que o provedor devolve.', 340);
  FAiModelsBtn := TUIButton.Create(Self);
  FAiModelsBtn.Caption := 'Listar';
  FAiModelsBtn.Variant := bvOutline;
  FAiModelsBtn.AutoWidth := True;
  FAiModelsBtn.OnClick := AiListModelsClick;
  FAiModelsBtn.AlignWithMargins := True;
  FAiModelsBtn.Margins.SetBounds(Sp(S.S2), 0, 0, 0);
  FAiModelsBtn.Align := alRight;
  FAiModelsBtn.Parent := Host;
  FAiModel := TUIInput.Create(Self);
  FAiModel.ReserveHintSpace := False;
  FAiModel.OnBlur := AiSettingChange;
  FAiModel.Align := alClient;
  FAiModel.Parent := Host;
  FAiModelsMenu := TUIDropdown.Create(Self);
  FAiModelsMenu.AnchorControl := FAiModel;
  FAiModelsMenu.AnchorPos := dapBottomLeft;
  FAiModelsMenu.MaxHeight := ScaleValue(320);
  FAiModelsMenu.OnItemClick := AiModelPicked;

  Host := NewRow(Card, 'Preço (US$ por milhão de tokens)',
    'Entrada e saída. Claude já vem com o preço público; nos outros, preencha para ver o custo.', 320);
  FAiPriceOut := TUINumberInput.Create(Self);
  FAiPriceOut.PrefixText := 'saída';
  FAiPriceOut.DecimalPlaces := 2;
  FAiPriceOut.Step := 0.1;
  FAiPriceOut.Max := 1000;
  FAiPriceOut.OnChange := AiSettingChange;
  FAiPriceOut.AlignWithMargins := True;
  FAiPriceOut.Margins.SetBounds(Sp(S.S2), 0, 0, 0);
  FAiPriceOut.Align := alClient;
  FAiPriceOut.Parent := Host;
  FAiPriceIn := TUINumberInput.Create(Self);
  FAiPriceIn.PrefixText := 'entrada';
  FAiPriceIn.DecimalPlaces := 2;
  FAiPriceIn.Step := 0.1;
  FAiPriceIn.Max := 1000;
  FAiPriceIn.OnChange := AiSettingChange;
  FAiPriceIn.Width := ScaleValue(156);
  FAiPriceIn.Align := alLeft;
  FAiPriceIn.Parent := Host;

  Card := NewSection('IA automática', 6);
  Host := NewRow(Card, 'Limite por mês (US$)', 'Chegou no limite, o chat e as tarefas automáticas param ' +
    'até o mês virar. 0 = sem limite.', 160);
  FAiCap := TUINumberInput.Create(Self);
  FAiCap.DecimalPlaces := 2;
  FAiCap.Step := 1;
  FAiCap.Max := 10000;
  FAiCap.Value := AiMonthCap;
  FAiCap.OnChange := AiAutoChange;
  FAiCap.Align := alClient;
  FAiCap.Parent := Host;
  Host := NewRow(Card, 'Modelo das tarefas automáticas', 'Mais barato que o do chat. Vazio = o mesmo do chat.', 300);
  FAiCheap := TUIInput.Create(Self);
  FAiCheap.ReserveHintSpace := False;
  FAiCheap.Value := AiCheapModel;
  FAiCheap.OnBlur := AiAutoChange;
  FAiCheap.Align := alClient;
  FAiCheap.Parent := Host;
  for UK := 0 to 3 do
  begin
    case UK of
      0: Host := NewRow(Card, 'Resumo do dia escrito pela IA', 'No horário do resumo. Sem IA, vai o resumo em números.', 60);
      1: Host := NewRow(Card, 'Alerta de risco', 'Uma vez por dia: até 3 issues com chance de atrasar ou travar.', 60);
      2: Host := NewRow(Card, 'Rascunho de horas no fim do dia', 'Às 17:30, em dias úteis. O assistente lança se você pedir.', 60);
      3: Host := NewRow(Card, 'Causa da falha do CI', 'Quando um PR seu fica vermelho, lê o log do job e explica.', 60);
    end;
    FAiAuto[UK] := TUIToggle.Create(Self);
    FAiAuto[UK].Checked := Store.GetSetting(IfThen(UK = 0, 'ai_daily', IfThen(UK = 1, 'ai_risk',
      IfThen(UK = 2, 'ai_eod', 'ai_ci')))) = '1';
    FAiAuto[UK].OnChange := AiAutoChange;
    FAiAuto[UK].Width := ScaleValue(60);
    FAiAuto[UK].Align := alLeft;
    FAiAuto[UK].Parent := Host;
  end;

  // Uso: números do mês e custo por dia.
  Card := NewSection('Uso da IA (custo estimado)', 0);
  Card.Height := ScaleValue(44 + 120 + 70 + 16);
  Row := NewPanel(Card, alNone, 120);
  Row.Top := 1000;
  Row.Align := alTop;
  for UK := 0 to 3 do
  begin
    FAiStats[UK] := TUIStat.Create(Self);
    FAiStats[UK].AlignWithMargins := True;
    FAiStats[UK].Margins.SetBounds(0, 0, Sp(S.S2), 0);
    FAiStats[UK].Width := ScaleValue(176);
    FAiStats[UK].Left := (UK + 1) * 1000;
    FAiStats[UK].Align := alLeft;
    FAiStats[UK].Parent := Row;
  end;
  FAiStats[0].CardLabel := 'Perguntas no mês';
  FAiStats[1].CardLabel := 'Tokens por pergunta';
  FAiStats[1].SubText := 'média, entrada + saída';
  FAiStats[2].CardLabel := 'Custo no mês';
  FAiStats[2].ValueFormat := nfDecimal;
  FAiStats[2].ValueDecimals := 2;
  FAiStats[2].ValuePrefix := 'US$ ';
  FAiStats[3].CardLabel := 'Custo por pergunta';
  FAiStats[3].ValueFormat := nfDecimal;
  FAiStats[3].ValueDecimals := 4;
  FAiStats[3].ValuePrefix := 'US$ ';
  FAiCostSpark := TUISparkline.Create(Self);
  FAiCostSpark.Kind := skBar;
  FAiCostSpark.Color := UITheme.Tokens.Color.Primary;
  FAiCostSpark.Hint := 'Custo por dia, últimos 30 dias';
  FAiCostSpark.ShowHint := True;
  FAiCostSpark.AlignWithMargins := True;
  FAiCostSpark.Margins.SetBounds(0, Sp(S.S3), 0, 0);
  FAiCostSpark.Height := ScaleValue(56);
  FAiCostSpark.Parent := Card;
  FAiCostSpark.Top := 2000;
  FAiCostSpark.Align := alTop;
  LoadAiSettings;
  UpdateAiUsage;
end;

procedure TMainForm.SettingsResize(Sender: TObject);
var
  I, H: Integer;
  C: TControl;
begin
  if FSettingsColumn = nil then
    Exit;
  // Altura = soma dos cartões (alTop com altura fixa) + respiro no fim.
  H := ScaleValue(16);
  for I := 0 to FSettingsColumn.ControlCount - 1 do
  begin
    C := FSettingsColumn.Controls[I];
    Inc(H, C.Height + C.Margins.Top);
  end;
  FSettingsColumn.SetBounds(Max(0, (FSettingsScroll.ClientWidth - FSettingsColumn.Width) div 2), 0,
    FSettingsColumn.Width, H);
  FSettingsScroll.ContentHeight := H;
end;

{ Campos do assistente para o provedor escolhido. }
procedure TMainForm.LoadAiSettings;
var
  Cfg: TAiConfig;
  PIn, POut: Double;
begin
  FAiLoading := True;
  try
    Cfg := CurrentAiConfig;
    FAiProvider.ItemIndex := Ord(Cfg.Kind);
    FAiBaseUrl.Value := Cfg.BaseUrl;
    FAiBaseUrl.LabelText := IfThen(Cfg.Kind = apAnthropic, 'Padrão da Anthropic', 'https://...');
    FAiModel.Value := Cfg.Model;
    FAiModel.LabelText := 'ex.: ' + IfThen(Cfg.Kind = apAnthropic, AiDefaultModel, 'nome do modelo');
    FApiKey.LabelText := IfThen(Cfg.ApiKey <> '', 'Chave salva (digite para trocar)',
      IfThen(Cfg.Kind = apOllama, 'Ollama local não precisa de chave', 'Cole a chave aqui'));
    AiPriceFor(Cfg.Model, PIn, POut);
    FAiPriceIn.Value := PIn;
    FAiPriceOut.Value := POut;
  finally
    FAiLoading := False;
  end;
end;

procedure TMainForm.AiSettingChange(Sender: TObject);
var
  Id: string;
begin
  if FAiLoading then
    Exit;
  if Sender = FAiProvider then
  begin
    Store.SetSetting('ai_provider', AiProviderIds[TAiProviderKind(FAiProvider.ItemIndex)]);
    LoadAiSettings;
    Exit;
  end;
  Id := AiProviderIds[CurrentAiConfig.Kind];
  if Sender = FAiBaseUrl then
    Store.SetSetting('ai_base_' + Id, FAiBaseUrl.Value.Trim)
  else if Sender = FAiModel then
  begin
    Store.SetSetting('ai_model_' + Id, FAiModel.Value.Trim);
    LoadAiSettings;  // preço do modelo novo
  end
  else if ((Sender = FAiPriceIn) or (Sender = FAiPriceOut)) and (FAiModel.Value.Trim <> '') then
    SetAiPrice(FAiModel.Value.Trim, FAiPriceIn.Value, FAiPriceOut.Value);
end;

procedure TMainForm.AiListModelsClick(Sender: TObject);
var
  Cfg: TAiConfig;
begin
  Cfg := CurrentAiConfig;
  FAiModelsBtn.Loading := True;
  TTask.Run(
    procedure
    var
      Models: TArray<string>;
      Err: string;
    begin
      try
        Models := ListAiModels(Cfg);
      except
        on E: Exception do
          Err := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        var
          M: string;
        begin
          FAiModelsBtn.Loading := False;
          if Err <> '' then
          begin
            TUIToastManager.Show('Não listou: ' + Err, TUIToastTone(2), 6000);
            Exit;
          end;
          FAiModelsMenu.ClearItems;
          for M in Models do
            FAiModelsMenu.AddItem(M, M);
          if Models = nil then
            TUIToastManager.Show('O provedor não devolveu modelos', TUIToastTone(3))
          else
            FAiModelsMenu.Open;
        end);
    end);
end;

procedure TMainForm.AiModelPicked(Sender: TObject; const AID: string);
begin
  FAiModel.Value := AID;
  AiSettingChange(FAiModel);
end;

{ Painel de uso: mês corrente e custo por dia (30 dias). }
{ Uma vez por dia busca a cotação (em segundo plano) e redesenha o card. }
procedure TMainForm.RefreshUsdBrl;
var
  Today: string;
begin
  Today := FormatDateTime('yyyy-mm-dd', Date);
  if (Store.GetSetting('usd_brl_date') = Today) or FFetchingRate then
    Exit;
  FFetchingRate := True;
  TTask.Run(
    procedure
    var
      Rate: Double;
    begin
      try
        Rate := FetchUsdBrl;
      except
        Rate := 0;  // sem rede: tenta de novo na próxima vez que abrir o card
      end;
      TThread.Queue(nil,
        procedure
        begin
          FFetchingRate := False;
          if Rate <= 0 then
            Exit;
          Store.SetSetting('usd_brl', FloatToStr(Rate, TFormatSettings.Invariant));
          Store.SetSetting('usd_brl_date', Today);
          UpdateAiUsage;
        end);
    end);
end;

procedure TMainForm.UpdateAiUsage;
var
  Count, TIn, TOut, I: Integer;
  Cost, Rate: Double;
  PerDay: TArray<Double>;
  Points: string;
  Fmt: TFormatSettings;
begin
  if FAiStats[0] = nil then
    Exit;
  Store.AiTotals(StartOfTheMonth(Now), Count, TIn, TOut, Cost);
  FAiStats[0].NumericValue := Count;
  FAiStats[1].NumericValue := IfThen(Count > 0, (TIn + TOut) / Max(Count, 1), 0);
  FAiStats[2].NumericValue := Cost;
  FAiStats[3].NumericValue := IfThen(Count > 0, Cost / Max(Count, 1), 0);
  FAiStats[0].SubText := Format('%d entrada · %d saída', [TIn, TOut]);
  Fmt := TFormatSettings.Invariant;
  // Fica em dólar; o real vai pequeno embaixo, pela cotação do dia.
  Rate := StrToFloatDef(Store.GetSetting('usd_brl'), 0, Fmt);
  if Rate > 0 then
  begin
    FAiStats[2].SubText := Format('≈ R$ %s · dólar a R$ %s', [FormatFloat('#,##0.00', Cost * Rate),
      FormatFloat('0.00', Rate)]);
    FAiStats[3].SubText := '≈ R$ ' + FormatFloat('#,##0.0000', IfThen(Count > 0, Cost / Max(Count, 1), 0) * Rate);
  end;
  RefreshUsdBrl;
  PerDay := Store.AiCostPerDay(30);
  Points := '';
  for I := 0 to High(PerDay) do
    Points := Points + IfThen(I > 0, ',') + FloatToStr(PerDay[I], Fmt);
  FAiCostSpark.DataPoints := Points;
end;

procedure TMainForm.TestNotifyClick(Sender: TObject);
begin
  Notify('Acme · APP-123 · Novo comentário',
    'Maria: pode validar o ajuste no checkout antes de subir?', '', stInfo, '*teste');
end;

{ Assistente da suíte: botão flutuante no canto, painel de conversa. As issues
  vão como contexto no prompt de sistema a cada busca. }
procedure TMainForm.BuildAssistant;
begin
  FAssistant := TUIAssistant.Create(Self);
  // FAB à direita, acima do rodapé da lista, por cima de todas as telas.
  FAssistant.Parent := Self;
  FAssistant.Anchors := [akRight, akBottom];
  FAssistant.SetBounds(ClientWidth - ScaleValue(96), ClientHeight - ScaleValue(150),
    ScaleValue(74), ScaleValue(74));
  FAssistant.Config.ApiKey := LoadSecret(AssistantSecret);
  FAssistant.Config.ApiKeyEnvVar := 'ANTHROPIC_API_KEY';
  FAssistant.Config.Model := AssistantModel;
  // Mascote animado (Lottie) por estado: ocioso, ouvindo, pensando, falando, dormindo.
  FAssistant.Behaviors.ApplyDefaults(ExtractFilePath(ParamStr(0)) + 'assets\assistant');
  FAssistant.Greeting := 'Posso resumir suas issues, registrar horas, comentar, mudar status e filtrar ' +
    'a tela. Toda escrita pede sua confirmação. Ex.: "o que vence esta semana?" ou "lance 2h na PROJ-1".';
  RegisterAiTools;
  FAssistant.BringToFront;
end;

{ ── Navegação ───────────────────────────────────────────────────────────── }

procedure TMainForm.ShowPage(APage: TPage);
var
  P, Old: TPage;
  Dir: TUIPageTransitionDirection;
begin
  Old := FPage;
  FPage := APage;
  // Prepara a página antes da transição: consulta ao banco e layout no meio do
  // deslize travavam os primeiros quadros, e a captura já sai com o conteúdo certo.
  if APage = pgSettings then
  begin
    FApiKey.Value := '';
    UpdateAiUsage;
    SettingsResize(nil);
  end;
  if (Old <> APage) and Visible and FContent.HandleAllocated then
  begin
    // Desliza para a direita indo para uma aba à direita, e o contrário.
    if Ord(APage) > Ord(Old) then
      Dir := tdForward
    else
      Dir := tdBackward;
    FTransition.Run(FContent, Dir,
      procedure
      var
        Q: TPage;
      begin
        for Q := Low(TPage) to High(TPage) do
          FPages[Q].Visible := Q = APage;
      end);
  end
  else
    for P := Low(TPage) to High(TPage) do
      FPages[P].Visible := P = APage;
  if FTabs.ActiveIndex <> Ord(APage) then
  begin
    FTabs.OnChange := nil;
    FTabs.ActiveIndex := Ord(APage);
    FTabs.OnChange := TabChange;
  end;
  PlaceAssistant;
end;

function TMainForm.PollIntervalMs: Integer;
begin
  // Em memória: o cabeçalho pergunta a cada segundo e ir ao banco toda vez é desperdício.
  if FPollMs = 0 then
  begin
    FPollMs := StrToIntDef(Store.GetSetting('poll_minutes'), DefaultPollMinutes) * 60 * 1000;
    // O relógio anda no menor intervalo; cada conta só busca quando chega a vez dela.
    for var Acc in Store.ListAccounts do
      if Acc.Enabled and (Acc.PollMinutes > 0) then
        FPollMs := Min(FPollMs, Acc.PollMinutes * 60 * 1000);
  end;
  Result := FPollMs;
end;

procedure TMainForm.GeneralSettingChange(Sender: TObject);
const
  Themes: array[0..2] of string = ('', 'light', 'dark');
begin
  if Sender = FAutostartToggle then
  begin
    SetAutostart(FAutostartToggle.Checked);
    FAutostartItem.Checked := AutostartEnabled;
  end
  else if Sender = FPollMinutes then
  begin
    Store.SetSetting('poll_minutes', IntToStr(Round(FPollMinutes.Value)));
    FPollMs := 0;
    FTimer.Interval := PollIntervalMs;
    FNextPoll := Now + PollIntervalMs / MSecsPerDay;
  end
  else if Sender = FNotifyStyle then
    Store.SetSetting('notify_style', IfThen(FNotifyStyle.ItemIndex = 1, 'windows', 'vigia'))
  else if Sender = FSummaryToggle then
    Store.SetSetting('summary_on', IfThen(FSummaryToggle.Checked, '1', '0'))
  else if Sender = FSummaryTime then
    Store.SetSetting('summary_time', Format('%.2d:%.2d', [FSummaryTime.Hour, FSummaryTime.Minute]))
  else if Sender = FDndToggle then
    Store.SetSetting('dnd_on', IfThen(FDndToggle.Checked, '1', '0'))
  else if Sender = FDndStart then
    Store.SetSetting('dnd_start', Format('%.2d:%.2d', [FDndStart.Hour, FDndStart.Minute]))
  else if Sender = FDndEnd then
    Store.SetSetting('dnd_end', Format('%.2d:%.2d', [FDndEnd.Hour, FDndEnd.Minute]))
  else if (Sender = FUpdateMode) and (FUpdateMode.ItemIndex >= 0) then
    Store.SetSetting('update_mode', IfThen(FUpdateMode.ItemIndex = 1, 'auto',
      IfThen(FUpdateMode.ItemIndex = 2, 'off', 'notify')))
  else if Sender = FNotifySeconds then
    Store.SetSetting('notify_seconds', IntToStr(Round(FNotifySeconds.Value)))
  else if (Sender = FThemeSelect) and (FThemeSelect.ItemIndex >= 0) then
  begin
    Store.SetSetting('theme', Themes[FThemeSelect.ItemIndex]);
    case FThemeSelect.ItemIndex of
      0: UITheme.Mode := tmSystem;
      1: UITheme.Mode := tmLight;
      2: UITheme.Mode := tmDark;
    end;
  end;
end;

{ O FAB da suíte recorta a janela no quadrado inteiro (74 px, com sombra), e
  os cantos mostravam o fundo liso por cima da lista. Recorta um círculo só um
  maior (1 px) que o desenhado (CFabInset = 8): a borda dura do recorte cai no
  fundo da mesma cor e não aparece; a borda do círculo continua com antialias. }
procedure TMainForm.ClipAssistant;
const
  FabInset = 8;
  Slack = 1;
var
  M: Integer;
begin
  if not FAssistant.HandleAllocated then
    Exit;
  M := ScaleValue(FabInset - Slack);
  SetWindowRgn(FAssistant.Handle, CreateEllipticRgn(M, M, FAssistant.Width - M + 1,
    FAssistant.Height - M + 1), True);
end;

{ O FAB vira filho do controle principal da tela: a suíte pinta nos cantos o
  que o pai desenha, então o círculo fica suave sobre a lista ou o painel
  (com o form de pai, os cantos mostravam o fundo do form por cima da lista). }
procedure TMainForm.PlaceAssistant;
var
  Host: TWinControl;
begin
  // Sempre a página: na lista de Issues a margem dela subia o FAB.
  Host := FPages[FPage];
  if FAssistant.Parent <> Host then
  begin
    FAssistant.Parent := Host;
    ClipAssistant;
  end;
  FAssistant.SetBounds(Host.ClientWidth - FAssistant.Width - ScaleValue(16),
    Host.ClientHeight - FAssistant.Height - ScaleValue(16), FAssistant.Width, FAssistant.Height);
  FAssistant.BringToFront;
end;

procedure TMainForm.TabChange(Sender: TObject; AIndex: Integer);
begin
  ShowPage(TPage(AIndex));
end;

procedure TMainForm.RebuildPalette;
var
  P: TPage;
  I: Integer;
  It: TItem;
begin
  FPalette.ClearItems;
  FPalette.AddCommand('Ações / Atualizar agora', procedure begin Poll(True); end, HeroIcon('arrow-path'));
  FPalette.AddCommand('Ações / Alternar tema claro e escuro',
    procedure
    begin
      FThemeSwap.Checked := not FThemeSwap.Checked;
      ThemeSwapToggle(nil);
    end, HeroIcon('sun'));
  FPalette.AddCommand('Ações / Nova conta', procedure begin NewAccountClick(nil); end, HeroIcon('squares-plus'));
  FPalette.AddCommand('Ações / Assistente IA', procedure begin FAssistant.Open; end, HeroIcon('fire'));
  for P := Low(TPage) to High(TPage) do
    FPalette.AddItem('page:' + IntToStr(Ord(P)), 'Ir para ' + PageTitles[P], '', 'Navegar');
  for I := 0 to High(FAll) do
  begin
    It := FAll[I];
    if not ItemInView(It) then
      Continue;
    FPalette.AddItem('issue:' + It.Key + '|' + IntToStr(It.AccountId),
      It.Key + '  ' + It.Title, '', 'Issues');
  end;
end;

procedure TMainForm.PaletteSelect(Sender: TObject; const AID: string);
var
  Parts: TArray<string>;
  I: Integer;
begin
  if AID.StartsWith('watch:') then
    WatchKey(AID.Substring(6))
  else if AID.StartsWith('page:') then
    ShowPage(TPage(StrToIntDef(AID.Substring(5), 0)))
  else if AID.StartsWith('issue:') then
  begin
    Parts := AID.Substring(6).Split(['|']);
    for I := 0 to High(FAll) do
      if SameText(FAll[I].Key, Parts[0]) and (IntToStr(FAll[I].AccountId) = Parts[1]) then
      begin
        OpenDetail(FAll[I]);
        Break;
      end;
  end;
end;

{ ── Contas ──────────────────────────────────────────────────────────────── }

function TMainForm.AccountById(AId: Integer; out AAccount: TAccount): Boolean;
var
  A: TAccount;
begin
  for A in FAccounts do
    if A.Id = AId then
    begin
      AAccount := A;
      Exit(True);
    end;
  Result := False;
end;

procedure TMainForm.ReloadAccounts;
var
  A: TAccount;
  State, Points: string;
  Card: TUICard;
  Av: TUIAvatar;
  Lbl: TUILabel;
  Spark: TUISparkline;
  PerDay: TArray<Integer>;
  Last: TDateTime;
  I, J, Y: Integer;
begin
  // Conta nova/editada: intervalo pode ter mudado e ela busca já.
  FPollMs := 0;
  FPollAll := True;
  FAccounts := Store.ListAccounts;

  // Um cartão por conta: avatar, estado, atividade de 14 dias e última busca.
  for I := FAccountsBox.InnerPanel.ControlCount - 1 downto 0 do
    FAccountsBox.InnerPanel.Controls[I].Free;
  Y := ScaleValue(4);
  for A in FAccounts do
  begin
    if not A.Enabled then
      State := 'desligada'
    else if FAccountErrors.ContainsKey(A.Id) then
      State := 'com erro na última busca'
    else
      State := 'ligada';
    Card := TUICard.Create(Self);
    Card.Variant := cvOutlined;
    Card.Clickable := True;
    Card.Hoverable := True;
    Card.Tag := A.Id;
    Card.OnClick := AccountCardClick;
    Card.Cursor := crHandPoint;
    Card.Parent := FAccountsBox.InnerPanel;
    Card.SetBounds(ScaleValue(16), Y, FAccountsBox.ClientWidth - ScaleValue(32), ScaleValue(96));
    Card.Anchors := [akLeft, akTop, akRight];

    Av := TUIAvatar.Create(Self);
    Av.Initials := Initials(A.Name);
    Av.Size := asLG;
    if not A.Enabled then
      Av.StatusColor := UITheme.Tokens.Color.FGMuted
    else if FAccountErrors.ContainsKey(A.Id) then
      Av.StatusColor := UITheme.Tokens.Color.Error
    else
      Av.StatusColor := UITheme.Tokens.Color.Success;
    Av.Parent := Card;
    Av.SetBounds(ScaleValue(16), ScaleValue(22), ScaleValue(52), ScaleValue(52));

    Lbl := TUILabel.Create(Self);
    Lbl.Caption := A.Name;
    Lbl.Bold := True;
    Lbl.FontSize := 15;
    Lbl.Parent := Card;
    Lbl.SetBounds(ScaleValue(84), ScaleValue(18), ScaleValue(360), ScaleValue(22));
    Lbl := TUILabel.Create(Self);
    Lbl.Caption := ProviderNames[A.Kind] + '  ·  ' + A.BaseUrl;
    Lbl.Variant := lvMuted;
    Lbl.Parent := Card;
    Lbl.SetBounds(ScaleValue(84), ScaleValue(42), ScaleValue(360), ScaleValue(18));
    Last := Store.LastPoll(A.Id);
    Lbl := TUILabel.Create(Self);
    if Last > 0 then
      Lbl.Caption := State + '  ·  última busca ' + FormatDateTime('dd/mm hh:nn', Last)
    else
      Lbl.Caption := State + '  ·  ainda não buscou';
    Lbl.Variant := lvMuted;
    Lbl.Parent := Card;
    Lbl.SetBounds(ScaleValue(84), ScaleValue(62), ScaleValue(360), ScaleValue(18));

    PerDay := Store.EventsPerDay(14, A.Id);
    Points := '';
    for J := 0 to High(PerDay) do
      Points := Points + IfThen(J > 0, ',') + IntToStr(PerDay[J]);
    Spark := TUISparkline.Create(Self);
    Spark.Kind := skArea;
    Spark.DataPoints := Points;
    Spark.Color := UITheme.Tokens.Color.Primary;
    Spark.Parent := Card;
    Spark.Anchors := [akTop, akRight];
    Spark.SetBounds(Card.Width - ScaleValue(200), ScaleValue(24), ScaleValue(176), ScaleValue(48));
    Spark.Hint := 'Avisos por dia, últimos 14 dias';
    Spark.ShowHint := True;

    // Os filhos não repassam o clique ao cartão: liga o mesmo handler neles.
    for J := 0 to Card.ControlCount - 1 do
    begin
      Card.Controls[J].Tag := A.Id;
      TClickAccess(Card.Controls[J]).OnClick := AccountCardClick;
      Card.Controls[J].Cursor := crHandPoint;
    end;
    Inc(Y, ScaleValue(108));
  end;
  FAccountsBox.ContentHeight := Y;
  FAccountsEmpty.Visible := FAccounts = nil;
  FAccountsBox.Visible := FAccounts <> nil;

  RebuildAccountMenu;
end;

{ Menu do seletor de conta. A escolha vale por usuário e filtra lista,
  Dashboard e Ctrl+K. Conta que sumiu volta para "Todas". }
procedure TMainForm.RebuildAccountMenu;
var
  A: TAccount;
  Found: Boolean;
begin
  Found := FAccountFilter = 0;
  FAccountMenu.ClearItems;
  FAccountMenu.AddItem('0', 'Todas as contas', HeroIcon('squares-2x2'));
  if FAccounts <> nil then
    FAccountMenu.AddSeparator;
  for A in FAccounts do
  begin
    FAccountMenu.AddItem(IntToStr(A.Id), A.Name, HeroIcon('signal'));
    FAccountMenu.SetItemDetail(IntToStr(A.Id), ShortProviderNames[A.Kind]);
    Found := Found or (A.Id = FAccountFilter);
  end;
  if not Found then
    FAccountFilter := 0;
  FAccountBtn.Caption := 'Todas as contas  ▾';
  for A in FAccounts do
    if A.Id = FAccountFilter then
      FAccountBtn.Caption := A.Name + '  ▾';
end;

procedure TMainForm.AccountBtnClick(Sender: TObject);
begin
  FAccountMenu.Open;
end;

procedure TMainForm.AccountMenuClick(Sender: TObject; const AID: string);
begin
  FAccountFilter := StrToIntDef(AID, 0);
  Store.SetSetting('account_filter', IntToStr(FAccountFilter));
  RebuildAccountMenu;
  FDetail.Visible := False;
  ReloadTags;
  RebuildRepoMenu;
  ApplyFilters;
  UpdateViews;
  RebuildPalette;
  UpdateHeader;
end;
function TMainForm.InFilter(AAccountId: Integer): Boolean;
begin
  Result := (FAccountFilter = 0) or (FAccountFilter = AAccountId);
end;

function TMainForm.ItemInView(const AItem: TItem): Boolean;
begin
  Result := InFilter(AItem.AccountId) and
    ((FRepoFilter = '') or SameText(RepoOf(AItem.Key), FRepoFilter));
end;

{ Repositórios das issues do GitHub na conta escolhida, com a quantidade.
  O botão só aparece quando há GitHub na tela. }
procedure TMainForm.RebuildRepoMenu;
var
  It: TItem;
  Counts: TDictionary<string, Integer>;
  Repos: TArray<string>;
  R: string;
  N: Integer;
begin
  Counts := TDictionary<string, Integer>.Create;
  try
    for It in FAll do
      if InFilter(It.AccountId) and (RepoOf(It.Key) <> '') then
      begin
        R := RepoOf(It.Key);
        if not Counts.TryGetValue(R, N) then
          N := 0;
        Counts.AddOrSetValue(R, N + 1);
      end;
    Repos := Counts.Keys.ToArray;
    TArray.Sort<string>(Repos, TComparer<string>.Construct(
      function(const L, Rr: string): Integer
      begin
        Result := CompareText(L, Rr);
      end));
    if (FRepoFilter <> '') and not Counts.ContainsKey(FRepoFilter) then
      FRepoFilter := '';
    FRepoMenu.ClearItems;
    FRepoMenu.AddItem('', 'Todos os repositórios', HeroIcon('squares-2x2'));
    FRepoMenu.SetItemDetail('', IntToStr(Length(Repos)));
    if Repos <> nil then
      FRepoMenu.AddSeparator;
    for R in Repos do
    begin
      FRepoMenu.AddItem(R, R);
      FRepoMenu.SetItemDetail(R, IntToStr(Counts[R]));
    end;
    if (Repos <> nil) and not FRepoBtn.Visible then
      // alRight decide pela posição: logo à esquerda da conta, senão ia para a ponta.
      FRepoBtn.Left := FAccountBtn.Left - 1;
    FRepoBtn.Visible := Repos <> nil;
    if FRepoFilter = '' then
      FRepoBtn.Caption := 'Todos os repositórios  ▾'
    else
      FRepoBtn.Caption := FRepoFilter.Substring(FRepoFilter.IndexOf('/') + 1) + '  ▾';
  finally
    Counts.Free;
  end;
end;

procedure TMainForm.RepoBtnClick(Sender: TObject);
begin
  FRepoMenu.Open;
end;

procedure TMainForm.RepoMenuClick(Sender: TObject; const AID: string);
begin
  SetRepoFilter(AID);
end;

procedure TMainForm.SetRepoFilter(const ARepo: string);
begin
  FRepoFilter := ARepo;
  Store.SetSetting('repo_filter', FRepoFilter);
  RebuildRepoMenu;
  FDetail.Visible := False;
  ApplyFilters;
  UpdateViews;
  RebuildPalette;
  UpdateHeader;
end;

{ Tags da conta escolhida (todas com "Todas as contas"). }
procedure TMainForm.ReloadTags;
var
  T: TTag;
begin
  FTags := nil;
  for T in Store.ListTags do
    if (FAccountFilter = 0) or (T.AccountId = FAccountFilter) then
      FTags := FTags + [T];
  RebuildTagChips;
end;

function TMainForm.FilteredItems: TItems;
var
  It: TItem;
begin
  Result := nil;
  for It in FAll do
    if ItemInView(It) then
      Result := Result + [It];
end;
procedure TMainForm.AccountCardClick(Sender: TObject);
var
  A: TAccount;
begin
  if AccountById(TComponent(Sender).Tag, A) and EditAccount(Self, A) then
  begin
    ReloadAccounts;
    LoadItems;
    Poll(False);
  end;
end;
procedure TMainForm.NewAccountClick(Sender: TObject);
begin
  if EditAccount(Self, NewAccount(pkGitHub)) then
  begin
    ReloadAccounts;
    Poll(False);
  end;
end;

procedure TMainForm.SaveApiKeyClick(Sender: TObject);
begin
  if FApiKey.Value.Trim = '' then
  begin
    TUIToastManager.Show('Informe a chave', ttWarning);
    Exit;
  end;
  SaveSecret(AiSecretTarget(CurrentAiConfig.Kind), '', FApiKey.Value.Trim);
  FApiKey.Value := '';
  FApiKey.LabelText := 'Chave salva (digite para trocar)';
  TUIToastManager.Show('Chave de ' + AiProviderNames[CurrentAiConfig.Kind] + ' salva.', ttSuccess);
end;

{ ── Issues ──────────────────────────────────────────────────────────────── }

function TMainForm.KeyOf(const AItem: TItem): string;
begin
  Result := IntToStr(AItem.AccountId) + '|' + AItem.Key.ToUpper;
end;

{ Linhas que mudaram brilham por ~1,4 s; as novas também entram deslizando. }
procedure TMainForm.FlashChanges(const AKeys: TArray<string>);
var
  K: string;
begin
  FFlashKeys.Clear;
  for K in AKeys do
    FFlashKeys.AddOrSetValue(K, True);
  if (FFlashKeys.Count = 0) and (FNewKeys.Count = 0) then
    Exit;
  FreeAndNil(FFlashAnim);
  FFlashAnim := TUIAnimation.Create(0, 1, 1400, aeLinear);
  FFlashAnim.OnUpdate :=
    procedure(const AValue: Single)
    begin
      FFlashValue := AValue;
      FItemsList.Invalidate;
    end;
  FFlashAnim.OnComplete :=
    procedure
    begin
      FFlashKeys.Clear;
      FNewKeys.Clear;
      FFlashValue := 1;
      FItemsList.Invalidate;
    end;
  FFlashValue := 0;
  FFlashAnim.Start;
end;

function TMainForm.IsManual(const AItem: TItem): Boolean;
begin
  Result := FManual.ContainsKey(IntToStr(AItem.AccountId) + '|' + AItem.Key.ToUpper);
end;

{ Lê o snapshot do banco (uma vez por busca) e reaplica os filtros em memória. }
procedure TMainForm.LoadItems;
var
  A: TAccount;
  K: string;
  It: TItem;
  MutedRules: TDictionary<string, TMuteRule>;
  Rule: TMuteRule;
begin
  FAll := nil;
  FManual.Clear;
  FOverdue := False;
  for A in FAccounts do
    if A.Enabled then
    begin
      FAll := FAll + Store.LoadSnapshot(A.Id);
      for K in Store.ListManualKeys(A.Id) do
        FManual.AddOrSetValue(IntToStr(A.Id) + '|' + K.ToUpper, True);
    end;
  ReloadTags;
  RebuildRepoMenu;
  FMuted.Clear;
  MutedRules := Store.LoadMuted;
  FDueSoon := False;
  for It in FAll do
  begin
    if IsOverdue(It) then
      FOverdue := True;
    if (It.DueDate > 0) and AccountById(It.AccountId, A) and (DueTone(It.DueDate, A) <> btSuccess) then
      FDueSoon := True;
    if MutedRules.TryGetValue(KeyOf(It), Rule) then
      if Rule.Active(It.Status) then
        FMuted.AddOrSetValue(KeyOf(It), True)
      else
        Store.Unmute(It.AccountId, It.Key);  // prazo ou status passou: solta
  end;
  MutedRules.Free;

  // Com prazo primeiro (mais perto em cima), depois associadas, depois mais recentes.
  TArray.Sort<TItem>(FAll, TComparer<TItem>.Construct(
    function(const L, R: TItem): Integer
    begin
      Result := Ord(R.DueDate > 0) - Ord(L.DueDate > 0);
      if (Result = 0) and (L.DueDate > 0) then
        Result := CompareValue(L.DueDate, R.DueDate);
      if Result = 0 then
        Result := Ord(isAssigned in R.Sources) - Ord(isAssigned in L.Sources);
      if Result = 0 then
        Result := CompareValue(R.UpdatedAt, L.UpdatedAt);
    end));
  ApplyFilters;
  UpdateViews;
  RebuildPalette;
  UpdateAssistantContext;
  UpdateHeader;
  UpdateTrayIcon;
end;

procedure TMainForm.UpdateViews;
begin
  FDashboard.AccountFilter := FAccountFilter;
  FDashboard.Update(FilteredItems, FAccounts);
end;

{ Tudo o que o Vigia sabe vai no prompt de sistema: contas, issues (com o
  último comentário) e avisos recentes. O assistente responde sobre qualquer
  tela sem precisar navegar. Tokens nunca entram aqui. }
procedure TMainForm.UpdateAssistantContext;
begin
  FAssistant.Config.SystemPrompt := BuildAiContext;
end;

function TMainForm.BuildAiContext: string;
const
  MaxEvents = 40;
  MaxCommentChars = 300;
var
  Sb: TStringBuilder;
  It: TItem;
  A: TAccount;
  E: TEvent;
  Err: string;
begin
  Sb := TStringBuilder.Create;
  try
    Sb.AppendLine('Você é o assistente do Vigia, um app de bandeja que acompanha issues do GitHub e do Jira ' +
      'para o usuário ' + GetEnvironmentVariable('USERNAME') + '.');
    Sb.AppendLine('Responda em português do Brasil, curto e direto, citando as chaves das issues. ' +
      'Hoje é ' + FormatDateTime('dddd, dd/mm/yyyy hh:nn', Now) + '.');
    Sb.AppendLine('Você tem ferramentas para agir: registrar horas, comentar, mudar status, marcar impedimento, ' +
      'atribuir, criar issue, abrir uma issue na tela, acompanhar, criar tag e filtrar a lista. Toda escrita no ' +
      'Jira/GitHub pede confirmação do usuário na própria conversa. Use vigia_issue_details para ler descrição ' +
      'e comentários antes de responder sobre o conteúdo de uma issue.');
    if FHoursWeek > 0 then
      Sb.AppendLine(Format('Horas lançadas no Jira: %.1fh hoje, %.1fh na semana.', [FHoursToday, FHoursWeek]));
    if Store.GetSetting('ai_eod_draft') <> '' then
    begin
      Sb.AppendLine('Rascunho de horas de hoje (feito por você no fim do dia; o usuário pode pedir para lançar):');
      Sb.AppendLine(Store.GetSetting('ai_eod_draft'));
    end;
    Sb.AppendLine;
    Sb.AppendLine('## Contas');
    for A in FAccounts do
    begin
      if not FAccountErrors.TryGetValue(A.Id, Err) then
        Err := '';
      Sb.AppendFormat('- %s (%s, %s): %s; prazo laranja até %d dias, vermelho até %d dias%s',
        [A.Name, ProviderNames[A.Kind], A.BaseUrl, IfThen(A.Enabled, 'ligada', 'desligada'),
         A.WarnDays, A.CriticalDays, IfThen(Err <> '', '; ERRO na última busca: ' + Err, '')]);
      Sb.AppendLine;
    end;
    Sb.AppendLine;
    Sb.AppendLine('## Issues acompanhadas');
    Sb.AppendLine('chave | título | status | conta | vínculo | impedida | entrega | responsável | ' +
      'atualizada | comentários | último comentário');
    for It in FAll do
    begin
      if not AccountById(It.AccountId, A) then
        Continue;
      Sb.AppendFormat('%s | %s | %s | %s | %s | %s | %s | %s | %s | %d | %s%s', [It.Key, It.Title,
        It.Status, A.Name,
        IfThen(isAssigned in It.Sources, 'comigo', IfThen(IsManual(It), 'manual',
          IfThen(isReview in It.Sources, 'review', 'observando'))),
        IfThen(It.Flagged, 'sim', 'não'),
        IfThen(It.DueDate > 0, FormatDateTime('dd/mm/yyyy', It.DueDate), '-'),
        IfThen(It.Assignee <> '', It.Assignee, '-'),
        IfThen(It.UpdatedAt > 0, FormatDateTime('dd/mm hh:nn', TTimeZone.Local.ToLocalTime(It.UpdatedAt)), '-'),
        It.CommentCount,
        IfThen(It.LastCommentText <> '', It.LastCommentBy + ': ' +
          Copy(It.LastCommentText.Replace(#13, ' ').Replace(#10, ' '), 1, MaxCommentChars), '-'),
        IfThen(It.CiState <> '', ' | CI ' + It.CiState + IfThen(It.CiDetail <> '', ' (' + It.CiDetail + ')', ''), '') +
        IfThen(It.Reviewers <> '', ' | ' + It.Reviewers, '') +
        IfThen(isSprint in It.Sources, ' | sprint ativa', '')]);
      Sb.AppendLine;
    end;
    Sb.AppendLine;
    Sb.AppendLine('## Avisos recentes (mais novos primeiro)');
    for E in Store.ListRecentEvents(MaxEvents) do
    begin
      Sb.AppendFormat('%s | %s | %s | %s', [FormatDateTime('dd/mm hh:nn', E.At), E.Key,
        EventNames[E.Kind], E.Body]);
      Sb.AppendLine;
    end;
    Result := Sb.ToString;
  finally
    Sb.Free;
  end;
end;

function TMainForm.FindItem(const AKey: string; out AItem: TItem; out AAccount: TAccount): Boolean;
var
  It: TItem;
begin
  for It in FAll do
    if SameText(It.Key, AKey.Trim) and AccountById(It.AccountId, AAccount) then
    begin
      AItem := It;
      Exit(True);
    end;
  Result := False;
end;

procedure TMainForm.ToolItem(const AArgs: TJSONObject; out AItem: TItem; out AAccount: TAccount);
var
  Key: string;
begin
  Key := AArgs.GetValue<string>('key', '').Trim;
  if not FindItem(Key, AItem, AAccount) then
    raise Exception.CreateFmt('Issue %s não está entre as acompanhadas', [Key]);
end;

{ Ferramentas do assistente (só com Anthropic; o provedor compatível com OpenAI
  é só texto). Escrita = RequiresConfirm: o chat pede Permitir/Negar antes. }
procedure TMainForm.RegisterAiTools;
var
  D: TUIAssistantToolDef;

begin
  D := FAssistant.Tools.Register('vigia_issue_details',
    'Lê descrição, anexos, ligações e os últimos comentários de uma issue.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
      Info: TIssueInfo;
      C: TComment;
      L: TIssueLink;
    begin
      ToolItem(AArgs, It, A);
      Info := FetchIssueInfo(A, LoadSecret(A.SecretTarget), It.Key);
      Result := 'Descrição: ' + Copy(Info.Description, 1, 4000) + sLineBreak;
      for L in Info.Links do
        Result := Result + Format('Ligação: %s %s (%s)', [L.Kind, L.Key, L.Summary]) + sLineBreak;
      for C in FetchComments(A, LoadSecret(A.SecretTarget), It.Key, 10) do
        Result := Result + Format('Comentário de %s em %s: %s', [C.Author,
          FormatDateTime('dd/mm hh:nn', TTimeZone.Local.ToLocalTime(C.At)), Copy(C.Text, 1, 1500)]) + sLineBreak;
    end);
  D.AddParam('key', pkString, 'Chave da issue, ex.: PROJ-123 ou dono/repo#12', True);

  D := FAssistant.Tools.Register('vigia_log_hours', 'Registra horas trabalhadas numa issue do Jira.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
      Day: TDateTime;
      Start: string;
    begin
      ToolItem(AArgs, It, A);
      if A.Kind = pkGitHub then
        raise Exception.Create('GitHub não tem registro de horas');
      Day := Date;
      if AArgs.GetValue<string>('date', '') <> '' then
        Day := ISO8601ToDate(AArgs.GetValue<string>('date') + 'T00:00:00', False);
      Start := AArgs.GetValue<string>('start', '09:00');
      AddWorklog(A, LoadSecret(A.SecretTarget), It.Key, AArgs.GetValue<Double>('hours'),
        Day + EncodeTime(StrToIntDef(Copy(Start, 1, 2), 9), StrToIntDef(Copy(Start, 4, 2), 0), 0, 0),
        AArgs.GetValue<string>('note', ''));
      Poll(False);
      Result := 'Horas registradas';
    end, True);
  D.AddParam('key', pkString, 'Chave da issue', True);
  D.AddParam('hours', pkNumber, 'Horas, ex.: 1.5', True);
  D.AddParam('date', pkString, 'Dia no formato yyyy-mm-dd; vazio = hoje');
  D.AddParam('start', pkString, 'Hora de início HH:MM; vazio = 09:00');
  D.AddParam('note', pkString, 'O que foi feito');

  D := FAssistant.Tools.Register('vigia_comment', 'Publica um comentário na issue.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
    begin
      ToolItem(AArgs, It, A);
      PostComment(A, LoadSecret(A.SecretTarget), It.Key, AArgs.GetValue<string>('text'));
      Result := 'Comentário publicado';
    end, True);
  D.AddParam('key', pkString, 'Chave da issue', True);
  D.AddParam('text', pkString, 'Texto do comentário', True);

  D := FAssistant.Tools.Register('vigia_list_transitions', 'Lista os status para onde a issue pode ir agora.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
      T: TTransition;
    begin
      ToolItem(AArgs, It, A);
      Result := '';
      for T in FetchTransitions(A, LoadSecret(A.SecretTarget), It.Key) do
        Result := Result + T.ToStatus + IfThen(T.Fields <> nil, ' (pede campos na tela)', '') + sLineBreak;
    end);
  D.AddParam('key', pkString, 'Chave da issue', True);

  D := FAssistant.Tools.Register('vigia_change_status', 'Muda o status da issue (use um nome de vigia_list_transitions).',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
      T: TTransition;
      Want: string;
    begin
      ToolItem(AArgs, It, A);
      Want := AArgs.GetValue<string>('status', '');
      for T in FetchTransitions(A, LoadSecret(A.SecretTarget), It.Key) do
        if SameText(T.ToStatus, Want) or SameText(T.Name, Want) then
        begin
          if T.Fields <> nil then
            raise Exception.Create('Essa transição pede campos. Peça ao usuário para usar botão direito > Mudar status');
          ApplyTransition(A, LoadSecret(A.SecretTarget), It.Key, T);
          Poll(False);
          Exit('Status alterado para ' + T.ToStatus);
        end;
      raise Exception.CreateFmt('Status "%s" não disponível agora', [Want]);
    end, True);
  D.AddParam('key', pkString, 'Chave da issue', True);
  D.AddParam('status', pkString, 'Status de destino', True);

  D := FAssistant.Tools.Register('vigia_set_impediment', 'Jira: marca ou tira impedimento (Flagged) e comenta o motivo.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
    begin
      ToolItem(AArgs, It, A);
      SetImpediment(A, LoadSecret(A.SecretTarget), It.Key, AArgs.GetValue<Boolean>('on', True), AArgs.GetValue<string>('reason', ''));
      Poll(False);
      Result := 'Feito';
    end, True);
  D.AddParam('key', pkString, 'Chave da issue', True);
  D.AddParam('on', pkBoolean, 'true marca, false tira', True);
  D.AddParam('reason', pkString, 'Motivo (vira comentário)');

  D := FAssistant.Tools.Register('vigia_assign_me', 'Atribui a issue ao usuário.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
    begin
      ToolItem(AArgs, It, A);
      AssignToMe(A, LoadSecret(A.SecretTarget), It.Key);
      Poll(False);
      Result := 'Atribuída';
    end, True);
  D.AddParam('key', pkString, 'Chave da issue', True);

  D := FAssistant.Tools.Register('vigia_create_issue', 'Cria uma issue no Jira (projeto) ou GitHub (dono/repo).',
    function(const AArgs: TJSONObject): string
    var
      A: TAccount;
      Found: Boolean;
    begin
      Found := False;
      for A in FAccounts do
        if SameText(A.Name, AArgs.GetValue<string>('account', '')) then
        begin
          Found := True;
          Result := 'Criada: ' + CreateIssue(A, LoadSecret(A.SecretTarget), AArgs.GetValue<string>('where'),
            AArgs.GetValue<string>('title'), AArgs.GetValue<string>('body', ''));
          Break;
        end;
      if not Found then
        raise Exception.Create('Conta não encontrada; use o nome que aparece em Contas');
    end, True);
  D.AddParam('account', pkString, 'Nome da conta no Vigia', True);
  D.AddParam('where', pkString, 'Chave do projeto Jira ou dono/repo do GitHub', True);
  D.AddParam('title', pkString, 'Título', True);
  D.AddParam('body', pkString, 'Descrição');

  D := FAssistant.Tools.Register('vigia_open_issue', 'Abre o painel da issue na tela do Vigia.',
    function(const AArgs: TJSONObject): string
    var
      It: TItem;
      A: TAccount;
    begin
      ToolItem(AArgs, It, A);
      OpenDetail(It);
      Result := 'Aberta';
    end);
  D.AddParam('key', pkString, 'Chave da issue', True);

  D := FAssistant.Tools.Register('vigia_watch', 'Passa a acompanhar uma issue pela chave (PROJ-123 ou dono/repo#12).',
    function(const AArgs: TJSONObject): string
    begin
      WatchKey(AArgs.GetValue<string>('key'));
      Result := 'Acompanhando';
    end);
  D.AddParam('key', pkString, 'Chave da issue', True);

  D := FAssistant.Tools.Register('vigia_create_tag', 'Cria uma #tag local que agrupa issues por palavras do título.',
    function(const AArgs: TJSONObject): string
    var
      T: TTag;
      A: TAccount;
    begin
      T := Default(TTag);
      T.Name := AArgs.GetValue<string>('name').Trim.TrimLeft(['#']);
      T.Keywords := AArgs.GetValue<string>('keywords', '');
      T.AccountId := 0;
      for A in FAccounts do
        if SameText(A.Name, AArgs.GetValue<string>('account', '')) or (T.AccountId = 0) then
          T.AccountId := A.Id;
      Store.SaveTag(T);
      ReloadTags;
      LoadItems;
      Result := 'Tag #' + T.Name + ' criada';
    end);
  D.AddParam('name', pkString, 'Nome sem #', True);
  D.AddParam('keywords', pkString, 'Palavras do título separadas por vírgula', True);
  D.AddParam('account', pkString, 'Nome da conta; vazio = primeira');

  D := FAssistant.Tools.Register('vigia_filter', 'Filtra a lista de Issues na tela.',
    function(const AArgs: TJSONObject): string
    var
      F: TItemFilter;
      Chips: string;
      I: Integer;
    begin
      ClearFiltersClick(nil);
      Chips := AArgs.GetValue<string>('chips', '');
      for F := Low(TItemFilter) to High(TItemFilter) do
        if ContainsText(Chips, FilterNames[F]) then
          FChips[F].Active := True;
      for I := 0 to High(FTags) do
        if SameText('#' + FTags[I].Name, AArgs.GetValue<string>('tag', '')) or
          SameText(FTags[I].Name, AArgs.GetValue<string>('tag', '')) then
          FTagChips[I].Active := True;
      if AArgs.GetValue<string>('repo', '') <> '' then
        SetRepoFilter(AArgs.GetValue<string>('repo'));
      ShowPage(pgIssues);
      ApplyFilters;
      Result := Format('%d issues na lista', [Length(FShown)]);
    end);
  D.AddParam('chips', pkString, 'Filtros separados por vírgula: Comigo, Atrasadas, Review, Manuais, ' +
    'Impedidas, Meus PRs, Sprint');
  D.AddParam('tag', pkString, 'Nome de uma tag');
  D.AddParam('repo', pkString, 'dono/repo do GitHub');
end;

{ ── IA automática (opt-in) ── }

procedure TMainForm.AiAutoChange(Sender: TObject);
const
  Keys: array[0..3] of string = ('ai_daily', 'ai_risk', 'ai_eod', 'ai_ci');
var
  I: Integer;
begin
  if Sender = FAiCap then
    Store.SetSetting('ai_month_cap', FloatToStr(FAiCap.Value, TFormatSettings.Invariant))
  else if Sender = FAiCheap then
    Store.SetSetting('ai_cheap_model_' + AiProviderIds[CurrentAiConfig.Kind], FAiCheap.Value.Trim)
  else
    for I := 0 to High(FAiAuto) do
      if Sender = FAiAuto[I] then
        Store.SetSetting(Keys[I], IfThen(FAiAuto[I].Checked, '1', '0'));
end;

{ PR com CI vermelho: lê o fim do log do job e pede a causa provável. }
procedure TMainForm.ExplainCiFailure(const AItem: TItem);
var
  A: TAccount;
  It: TItem;
begin
  if (Store.GetSetting('ai_ci') <> '1') or (AItem.CiUrl = '') or not AccountById(AItem.AccountId, A) then
    Exit;
  It := AItem;
  TTask.Run(
    procedure
    var
      Log: string;
    begin
      try
        Log := FetchJobLog(A, LoadSecret(A.SecretTarget), It.CiUrl);
      except
        on E: Exception do
          Log := '';
      end;
      if Log = '' then
        Exit;
      TThread.Queue(nil,
        procedure
        begin
          AiAsk('Você analisa falhas de CI. Responda em português, em até 3 frases curtas: causa provável e ' +
            'o que fazer. Sem markdown.', 'Job "' + It.CiDetail + '" do PR ' + It.Key + ' falhou. Fim do log:' +
            sLineBreak + Log, True,
            procedure(AText: string)
            begin
              Store.SetSetting('ai_ci_' + It.Key, AText);
              Notify('CI de ' + It.Key + ' · causa provável', AText, It.CiUrl, stError, It.Key, It.AccountId);
            end);
        end);
    end);
end;

{ Uma vez por dia cada: resumo (no horário do resumo), risco (após a 1ª busca)
  e rascunho de horas (a partir das 17:30). }
procedure TMainForm.RunAutoAi;
const
  EodTime = 17.5 / 24;
var
  Today: string;
begin
  if FLastPoll = 0 then
    Exit;
  Today := FormatDateTime('yyyy-mm-dd', Date);
  if (Store.GetSetting('ai_risk') = '1') and (Store.GetSetting('ai_risk_last') <> Today) then
  begin
    Store.SetSetting('ai_risk_last', Today);
    AiAsk(BuildAiContext, 'Aponte até 3 issues com maior risco de atrasar ou travar (prazo perto, impedida, ' +
      'parada há dias, CI falhando). Uma linha por issue: chave e motivo. Se não houver risco real, ' +
      'responda só NADA.', True,
      procedure(AText: string)
      begin
        if not SameText(AText, 'NADA') then
          Notify('Vigia · riscos de hoje', AText, '', stWarning, '*dashboard');
      end);
  end;
  if (Store.GetSetting('ai_eod') = '1') and (Frac(Now) >= EodTime) and
    (Store.GetSetting('ai_eod_last') <> Today) and (DayOfTheWeek(Date) <= 5) then
  begin
    Store.SetSetting('ai_eod_last', Today);
    AiAsk(BuildAiContext, Format('Fim do dia. Já lancei %.1fh hoje. Pelos avisos e issues de hoje, rascunhe ' +
      'lançamentos de horas que faltam: uma linha por issue no formato "CHAVE · horas · o que foi feito". ' +
      'Se não houver o que lançar, responda só NADA.', [FHoursToday]), True,
      procedure(AText: string)
      begin
        if SameText(AText, 'NADA') then
          Exit;
        Store.SetSetting('ai_eod_draft', AText);
        Notify('Vigia · rascunho de horas', AText + sLineBreak +
          'Peça ao assistente: "lance o rascunho de horas".', '', stInfo, '*dashboard');
      end);
  end;
end;

procedure TMainForm.ApplyFilters;
var
  It: TItem;
  A: TAccount;
  F: TItemFilter;
  AnyChip, Pass: Boolean;
  Tag, KeepKey: string;
  Tone: TUIBadgeTone;
  V: TUIVListItem;
  I, First: Integer;
  Sel: TItem;
  Badges: TBadges;
  Counts: array[TItemFilter] of Integer;
  TagCounts: TArray<Integer>;
  AnyTag, TagPass: Boolean;
  Active: string;
  T: Integer;
begin
  SetLength(TagCounts, Length(FTags));
  AnyTag := False;
  for T := 0 to High(FTagChips) do
    AnyTag := AnyTag or FTagChips[T].Active;
  AnyChip := False;
  for F := Low(TItemFilter) to High(TItemFilter) do
  begin
    AnyChip := AnyChip or FChips[F].Active;
    Counts[F] := 0;
  end;

  KeepKey := '';
  if SelectedItem(Sel) then
    KeepKey := Sel.Key;
  First := TListAccess(FItemsList).FirstVisible;

  FShown := nil;
  FShownTone := nil;
  FShownBadges := nil;
  FShownTag := nil;
  FItemsList.ClearItems;
  for It in FAll do
  begin
    if not ItemInView(It) then
      Continue;

    // Contador de cada chip antes de aplicar os chips.
    if isAssigned in It.Sources then Inc(Counts[ifMine]);
    if IsOverdue(It) then Inc(Counts[ifOverdue]);
    if isReview in It.Sources then Inc(Counts[ifReview]);
    if IsManual(It) then Inc(Counts[ifManual]);
    if It.Flagged then Inc(Counts[ifFlagged]);
    if isMine in It.Sources then Inc(Counts[ifMyPrs]);
    if isSprint in It.Sources then Inc(Counts[ifSprint]);
    for T := 0 to High(FTags) do
      if FTags[T].Matches(It) then
        Inc(TagCounts[T]);

    if not DrillPass(It) then
      Continue;

    // Tags somam entre si (OU) e filtram junto com os chips de cima (E).
    if AnyTag then
    begin
      TagPass := False;
      for T := 0 to High(FTags) do
        TagPass := TagPass or (FTagChips[T].Active and FTags[T].Matches(It));
      if not TagPass then
        Continue;
    end;

    if AnyChip then
    begin
      // Chips somam (OU): "Comigo" + "Atrasadas" mostra as duas coisas.
      Pass := (FChips[ifMine].Active and (isAssigned in It.Sources)) or
        (FChips[ifOverdue].Active and IsOverdue(It)) or
        (FChips[ifReview].Active and (isReview in It.Sources)) or
        (FChips[ifManual].Active and IsManual(It)) or
        (FChips[ifFlagged].Active and It.Flagged) or
        (FChips[ifMyPrs].Active and (isMine in It.Sources)) or
        (FChips[ifSprint].Active and (isSprint in It.Sources));
      if not Pass then
        Continue;
    end;

    if IsOverdue(It) then
    begin
      Tag := 'atrasada';
      Tone := btError;
    end
    else if isAssigned in It.Sources then
    begin
      Tag := 'comigo';
      Tone := btPrimary;
    end
    else if isReview in It.Sources then
    begin
      Tag := 'review';
      Tone := btInfo;
    end
    else if isMine in It.Sources then
    begin
      Tag := 'meu PR';
      Tone := btSuccess;
    end
    else if isMention in It.Sources then
    begin
      Tag := 'mencionado';
      Tone := btWarning;
    end
    else if isQuery in It.Sources then
    begin
      Tag := 'busca';
      Tone := btNeutral;
    end
    else if isOwnRepo in It.Sources then
    begin
      Tag := 'meu repo';
      Tone := btNeutral;
    end
    else if IsManual(It) then
    begin
      Tag := 'manual';
      Tone := btWarning;
    end
    else
    begin
      Tag := 'observando';
      Tone := btNeutral;
    end;

    Badges := nil;
    if (FAccountFilter = 0) and (Length(FAccounts) > 1) and AccountById(It.AccountId, A) then
      Badges := Badges + [Badge(A.Name, btNeutral)];
    for T := 0 to High(FTags) do
      if FTags[T].Matches(It) then
        Badges := Badges + [Badge('#' + FTags[T].Name, btSuccess)];
    if It.Status <> '' then
      Badges := Badges + [Badge(It.Status, StatusTone(It.StatusCategory))];
    if It.Flagged then
      Badges := Badges + [Badge('Impedida', btError)];
    if SameText(It.ReviewState, 'APPROVED') then
      Badges := Badges + [Badge('Aprovado', btSuccess)]
    else if SameText(It.ReviewState, 'CHANGES_REQUESTED') then
      Badges := Badges + [Badge('Mudanças pedidas', btWarning)];
    if MatchText(It.CiState, ['FAILURE', 'ERROR']) then
      Badges := Badges + [Badge('CI falhou', btError)]
    else if MatchText(It.CiState, ['PENDING', 'EXPECTED']) then
      Badges := Badges + [Badge('CI rodando', btInfo)]
    else if SameText(It.CiState, 'SUCCESS') then
      Badges := Badges + [Badge('CI ok', btSuccess)];
    if (It.DueDate > 0) and AccountById(It.AccountId, A) then
      Badges := Badges + [Badge(IfThen(A.DueField <> '', 'Entrega ', 'Prazo ') +
        FormatDateTime('dd/mm', It.DueDate), DueTone(It.DueDate, A))];
    if FMuted.ContainsKey(KeyOf(It)) then
      Badges := Badges + [Badge('silenciada', btGhost)];

    // A lista só desenha fundo, hover e seleção; as 3 linhas vêm do OnCustomDraw.
    V := Default(TUIVListItem);
    V.ID := It.Key;
    FItemsList.AddItem(V);
    FShown := FShown + [It];
    FShownTone := FShownTone + [Ord(Tone)];
    FShownBadges := FShownBadges + [Badges];
    FShownTag := FShownTag + [Tag];
  end;

  Store.SetSetting('group_list', IfThen(FGroupChip.Active, '1', ''));
  if FGroupChip.Active then
    RegroupShown;

  // Mantém a posição e a seleção entre recargas.
  for I := 0 to High(FShown) do
    if SameText(FShown[I].Key, KeepKey) then
      FItemsList.SelectIndex(I);
  if (First > 0) and (FShown <> nil) then
    TListAccess(FItemsList).ScrollTo(Min(First, High(FShown)) * FItemsList.RowHeight);

  for F := Low(TItemFilter) to High(TItemFilter) do
    FChips[F].Count := Counts[F];
  // Sprint só existe no Jira com Agile: sem itens, o chip some.
  if (Counts[ifSprint] > 0) or FChips[ifSprint].Active then
  begin
    FChips[ifSprint].Left := FChips[ifMyPrs].Left + FChips[ifMyPrs].Width + 1;
    FChips[ifSprint].Visible := True;
  end
  else
    FChips[ifSprint].Visible := False;
  for T := 0 to High(FTagChips) do
    FTagChips[T].Count := TagCounts[T];

  // Lista, esqueleto (primeira busca) ou vazio.
  FSkeleton.Visible := (FShown = nil) and (FAll = nil) and FPolling;
  FItemsEmpty.Visible := (FShown = nil) and not FSkeleton.Visible;
  FItemsList.Visible := FShown <> nil;
  if FItemsEmpty.Visible then
  begin
    if FAccounts = nil then
    begin
      FItemsEmpty.Title := 'Nenhuma conta ainda';
      FItemsEmpty.Description := 'Cadastre uma conta do GitHub ou do Jira em Contas.';
      FItemsEmpty.ActionLabel := 'Nova conta';
      FItemsEmpty.OnAction := NewAccountClick;
    end
    else if FAll = nil then
    begin
      FItemsEmpty.Title := 'Nada acompanhado ainda';
      FItemsEmpty.Description := 'A lista enche depois da primeira busca.';
      FItemsEmpty.ActionLabel := 'Atualizar agora';
      FItemsEmpty.OnAction := RefreshClick;
    end
    else
    begin
      // Diz o que está filtrando, para não parecer que sumiu tudo.
      Active := '';
      for F := Low(TItemFilter) to High(TItemFilter) do
        if FChips[F].Active then
          Active := Active + IfThen(Active <> '', ', ') + FilterNames[F];
      for T := 0 to High(FTagChips) do
        if FTagChips[T].Active then
          Active := Active + IfThen(Active <> '', ', ') + '#' + FTags[T].Name;
      if FDrill.Kind <> dkNone then
        Active := Active + IfThen(Active <> '', ', ') + FDrill.Caption;
      if FRepoFilter <> '' then
        Active := Active + IfThen(Active <> '', ', ') + FRepoFilter;
      FItemsEmpty.Title := 'Nada com esse filtro';
      FItemsEmpty.Description := IfThen(Active <> '', 'Filtrando por: ' + Active + '.',
        'Nenhuma issue nesta conta.');
      FItemsEmpty.ActionLabel := IfThen(Active <> '', 'Limpar filtros', '');
      FItemsEmpty.OnAction := ClearFiltersClick;
    end;
  end;
end;

procedure TMainForm.FilterChanged(Sender: TObject);
begin
  ApplyFilters;
end;

procedure TMainForm.ClearFiltersClick(Sender: TObject);
var
  F: TItemFilter;
  C: TUIFilterChip;
begin
  for F := Low(TItemFilter) to High(TItemFilter) do
    FChips[F].Active := False;
  for C in FTagChips do
    C.Active := False;
  FDrill := Default(TDrill);
  FDrillChip.Visible := False;
  if FRepoFilter <> '' then
    SetRepoFilter('')
  else
    ApplyFilters;
end;

{ Linha de cabeçalho: AccountId = -1, Key = nome do grupo; CommentCount = itens,
  DueAlert = atrasadas, Flagged por contagem em LastCommentText. }
function TMainForm.IsGroupRow(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex <= High(FShown)) and (FShown[AIndex].AccountId = -1);
end;

{ Reordena FShown em grupos (repositório no GitHub, projeto no Jira), do maior
  para o menor, com um cabeçalho por grupo. Grupo recolhido mostra só o cabeçalho. }
procedure TMainForm.RegroupShown;
var
  Names: TArray<string>;
  Idx: TDictionary<string, TList<Integer>>;
  G: string;
  I, J: Integer;
  H: TItem;
  L: TList<Integer>;
  Items: TItems;
  Tones: TArray<Integer>;
  Bdg: TArray<TBadges>;
  Tags: TArray<string>;
  V: TUIVListItem;
  Overdue, Flagged: Integer;

  function GroupOf(const AItem: TItem): string;
  begin
    Result := RepoOf(AItem.Key);
    if Result = '' then
      Result := AItem.Key.Substring(0, AItem.Key.IndexOf('-'));
  end;

begin
  Idx := TObjectDictionary<string, TList<Integer>>.Create([doOwnsValues]);
  try
    for I := 0 to High(FShown) do
    begin
      G := GroupOf(FShown[I]);
      if not Idx.TryGetValue(G, L) then
      begin
        L := TList<Integer>.Create;
        Idx.Add(G, L);
      end;
      L.Add(I);
    end;
    Names := Idx.Keys.ToArray;
    TArray.Sort<string>(Names, TComparer<string>.Construct(
      function(const A, B: string): Integer
      begin
        Result := Idx[B].Count - Idx[A].Count;
        if Result = 0 then
          Result := CompareText(A, B);
      end));
    FItemsList.ClearItems;
    for G in Names do
    begin
      L := Idx[G];
      Overdue := 0;
      Flagged := 0;
      for J in L do
      begin
        if IsOverdue(FShown[J]) then Inc(Overdue);
        if FShown[J].Flagged then Inc(Flagged);
      end;
      H := Default(TItem);
      H.AccountId := -1;
      H.Key := G;
      H.CommentCount := L.Count;
      H.DueAlert := Overdue;
      H.LastCommentText := IntToStr(Flagged);
      Items := Items + [H];
      Tones := Tones + [0];
      Bdg := Bdg + [nil];
      Tags := Tags + [''];
      V := Default(TUIVListItem);
      V.ID := '#grupo:' + G;
      FItemsList.AddItem(V);
      if FCollapsed.ContainsKey(G) then
        Continue;
      for J in L do
      begin
        Items := Items + [FShown[J]];
        Tones := Tones + [FShownTone[J]];
        Bdg := Bdg + [FShownBadges[J]];
        Tags := Tags + [FShownTag[J]];
        V := Default(TUIVListItem);
        V.ID := FShown[J].Key;
        FItemsList.AddItem(V);
      end;
    end;
    FShown := Items;
    FShownTone := Tones;
    FShownBadges := Bdg;
    FShownTag := Tags;
  finally
    Idx.Free;
  end;
end;

procedure TMainForm.DrawGroupRow(AIndex: Integer; const ACanvas: ISkCanvas; const ARowRect: TRectF);
var
  T: TUITokens;
  H: TItem;
  L, Cy, X: Single;
  NameFont, SubFont: ISkFont;
  Sub: string;
  Badges: TBadges;
begin
  T := UITheme.Tokens;
  H := FShown[AIndex];
  UIDrawRRectFill(ACanvas, ARowRect, 0, UIColorWithAlpha(T.Color.FG, 0.035));
  L := ARowRect.Left + 14;
  Cy := ARowRect.CenterPoint.Y;
  NameFont := TUIFontManager.GetFont(T.Typography.FamilyPrimary, 14, T.Typography.WeightSemiBold);
  SubFont := TUIFontManager.GetFont(T.Typography.FamilyPrimary, 12, T.Typography.WeightRegular);
  UIDrawText(ACanvas, IfThen(FCollapsed.ContainsKey(H.Key), '▸', '▾'),
    TRectF.Create(L, Cy - 12, L + 16, Cy + 12), NameFont, T.Color.FGMuted);
  X := L + 22;
  UIDrawText(ACanvas, H.Key, TRectF.Create(X, Cy - 12, ARowRect.Right - 200, Cy + 12), NameFont, T.Color.FG);
  Badges := [Badge(Format('%d', [H.CommentCount]), btNeutral)];
  if H.DueAlert > 0 then
    Badges := Badges + [Badge(Format('%d atrasada(s)', [H.DueAlert]), btError)];
  if StrToIntDef(H.LastCommentText, 0) > 0 then
    Badges := Badges + [Badge(H.LastCommentText + ' impedida(s)', btWarning)];
  DrawBadgeRow(ACanvas, X + UITextWidth(H.Key, NameFont) + 12, Cy, Badges, ARowRect.Right - 14);
  Sub := IfThen(FCollapsed.ContainsKey(H.Key), 'recolhido · clique para abrir', '');
  if Sub <> '' then
    UIDrawText(ACanvas, Sub, TRectF.Create(ARowRect.Right - 220, Cy - 10, ARowRect.Right - 14, Cy + 10),
      SubFont, T.Color.FGMuted, UI.Painter.taRight);
end;

{ Recria os chips de tag mantendo os que estavam ligados (por nome). }
procedure TMainForm.RebuildTagChips;
var
  Was: TArray<string>;
  C: TUIFilterChip;
  I: Integer;
begin
  Was := nil;
  for C in FTagChips do
  begin
    if C.Active then
      Was := Was + [C.Hint];
    C.Free;
  end;
  FTagChips := nil;
  for I := 0 to High(FTags) do
  begin
    C := TUIFilterChip.Create(Self);
    C.Caption := '#' + FTags[I].Name;
    C.Count := 0;
    C.Hint := FTags[I].Name;
    C.Tone := btSuccess;
    C.Active := IndexText(FTags[I].Name, Was) >= 0;
    C.OnToggle := FilterChanged;
    C.AlignWithMargins := True;
    C.Margins.SetBounds(0, 0, 8, 0);
    C.Left := (I + 1) * 1000;
    C.Align := alLeft;
    C.Parent := FTagBar;
    FTagChips := FTagChips + [C];
  end;
  FTagHint.Visible := FTags = nil;
end;

{ Rótulo fixo à esquerda da linha, para os chips das duas linhas alinharem. }
function TMainForm.NewRowLabel(AParent: TWinControl; const ACaption: string): TUILabel;
begin
  Result := TUILabel.Create(Self);
  Result.Caption := ACaption;
  Result.Variant := lvMuted;
  Result.AutoSize := False;
  Result.Width := ScaleValue(56);
  Result.Left := 0;
  Result.Align := alLeft;
  Result.Parent := AParent;
end;

{ Submenu "Tag" do menu da issue: Gerenciar e uma linha por tag (✓ nas da issue).
  ponytail: menu não rola; com muitas tags ele cresce até a borda da janela. }
procedure TMainForm.FillTagMenu(const AItem: TItem);
const
  Check = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
    'stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5L20 7"/></svg>';
var
  T: TTag;
begin
  FTagMenu.ClearItems;
  FTagMenu.AddItem('tag-manage', 'Gerenciar tags...', HeroIcon('squares-plus'));
  if FTags <> nil then
    FTagMenu.AddSeparator;
  for T in FTags do
    if T.AccountId <> AItem.AccountId then
      Continue
    else if T.HasManual(AItem.AccountId, AItem.Key) then
      FTagMenu.AddItem('tag:' + IntToStr(T.Id), '#' + T.Name, Check)
    else if T.ByKeyword(AItem.Title) then
      FTagMenu.AddItem('tag:' + IntToStr(T.Id), '#' + T.Name + '  (pelo título)', Check)
    else
      FTagMenu.AddItem('tag:' + IntToStr(T.Id), '#' + T.Name);
end;

procedure TMainForm.FillActionMenu(const AItem: TItem);
begin
  FActionMenu.ClearItems;
  FActionMenu.AddItem('act-assign', 'Atribuir a mim', HeroIcon('arrow-down-tray'));
  if Pos('#', AItem.Key) > 0 then
  begin
    FActionMenu.AddItem('act-label', 'Adicionar label...', HeroIcon('squares-plus'));
    if Pos('/pull/', AItem.Url) > 0 then
      FActionMenu.AddItem('act-approve', 'Aprovar PR', HeroIcon('check-circle'));
    if AItem.CiUrl <> '' then
      FActionMenu.AddItem('act-ci', 'Abrir job que falhou', HeroIcon('x-circle'));
  end
  else
  begin
    FActionMenu.AddItem('act-log', 'Registrar horas...', HeroIcon('clock'));
    FActionMenu.AddItem('act-priority', 'Mudar prioridade...', HeroIcon('arrow-trending-up'));
    FActionMenu.AddItem('act-label', 'Adicionar label...', HeroIcon('squares-plus'));
    if AItem.Flagged then
      FActionMenu.AddItem('act-unflag', 'Tirar impedimento...', HeroIcon('check-circle'))
    else
      FActionMenu.AddItem('act-flag', 'Marcar impedimento...', HeroIcon('exclamation-triangle'));
  end;
end;

{ Roda a escrita fora da UI; no fim avisa e busca de novo. A confirmação já
  aconteceu antes de chegar aqui. }
procedure TMainForm.RunAction(const AItem: TItem; const ADone: string; const AWork: TProc<TAccount, string>);
var
  A: TAccount;
begin
  if not AccountById(AItem.AccountId, A) then
    Exit;
  TTask.Run(
    procedure
    var
      Err: string;
    begin
      try
        AWork(A, LoadSecret(A.SecretTarget));
      except
        on E: Exception do
          Err := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if Err = '' then
          begin
            TUIToastManager.Show(ADone, ttSuccess);
            Poll(False);
          end
          else
            TUIToastManager.Show('Não deu certo: ' + Err, ttError, 6000);
        end);
    end);
end;

procedure TMainForm.TagMenuClick(Sender: TObject; const AID: string);
begin
  ItemMenuClick(Sender, AID);
end;

{ Linha da issue em 3 linhas: chave, título, selos. À direita: vínculo e
  data/hora da última atualização. }
procedure TMainForm.ItemsDraw(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem;
  const ACanvas: ISkCanvas; const ARowRect: TRectF);
const
  PadX = 14;
var
  T: TUITokens;
  It: TItem;
  L, R, Cy1, Cy2, Cy3, TitleMax: Single;
  KeyFont, TitleFont: ISkFont;
  Stamp: TBadge;
begin
  if AIndex > High(FShown) then
    Exit;
  if IsGroupRow(AIndex) then
  begin
    DrawGroupRow(AIndex, ACanvas, ARowRect);
    Exit;
  end;
  T := UITheme.Tokens;
  It := FShown[AIndex];
  // Brilho de "mudou" sumindo; linha nova entra deslizando 24 px.
  if FFlashKeys.ContainsKey(KeyOf(It)) or FNewKeys.ContainsKey(KeyOf(It)) then
    UIDrawRRectFill(ACanvas, ARowRect, 0, UIColorWithAlpha(T.Color.Primary, (1 - FFlashValue) * 0.22));
  L := ARowRect.Left + PadX;
  if FNewKeys.ContainsKey(KeyOf(It)) then
    L := L + 24 * (1 - TUIEasingFunctions.Apply(FFlashValue, aeEaseOutCubic));
  R := ARowRect.Right - PadX;
  Cy1 := ARowRect.Top + 17;
  Cy2 := ARowRect.Top + 38;
  Cy3 := ARowRect.Top + 59;

  KeyFont := TUIFontManager.GetFont(T.Typography.FamilyPrimary, 11.5, T.Typography.WeightSemiBold);
  TitleFont := TUIFontManager.GetFont(T.Typography.FamilyPrimary, 13, T.Typography.WeightMedium);

  DrawPillRight(ACanvas, R, Cy1, Badge(FShownTag[AIndex], TUIBadgeTone(FShownTone[AIndex])));
  Stamp := Badge('', btNeutral);
  if It.UpdatedAt > 0 then
  begin
    Stamp.Text := FormatDateTime('dd/mm hh:nn', TTimeZone.Local.ToLocalTime(It.UpdatedAt));
    DrawPillRight(ACanvas, R, Cy2, Stamp);
  end;

  UIDrawText(ACanvas, It.Key, TRectF.Create(L, Cy1 - 9, R - 110, Cy1 + 9), KeyFont, T.Color.Primary);
  TitleMax := R - L - IfThen(Stamp.Text <> '', UITextWidth(Stamp.Text, KeyFont) + 30, 0);
  UIDrawText(ACanvas, FitText(It.Title, TitleFont, TitleMax),
    TRectF.Create(L, Cy2 - 10, L + TitleMax, Cy2 + 10), TitleFont, T.Color.FG);
  DrawBadgeRow(ACanvas, L, Cy3, FShownBadges[AIndex], R);
end;

function TMainForm.SelectedItem(out AItem: TItem): Boolean;
var
  Sel: TArray<Integer>;
begin
  Sel := FItemsList.GetSelectedIndices;
  Result := (Sel <> nil) and (Sel[0] >= 0) and (Sel[0] <= High(FShown)) and not IsGroupRow(Sel[0]);
  if Result then
    AItem := FShown[Sel[0]];
end;

procedure TMainForm.OpenDetail(const AItem: TItem);
var
  A: TAccount;
  I: Integer;
begin
  if not AccountById(AItem.AccountId, A) then
    Exit;
  ShowPage(pgIssues);
  for I := 0 to High(FShown) do
    if SameText(FShown[I].Key, AItem.Key) and (FShown[I].AccountId = AItem.AccountId) then
    begin
      FItemsList.SelectIndex(I);
      FItemsList.ScrollToIndex(I);
    end;
  FDetail.ShowItem(AItem, A);
  SetDetailVisible(True);
  if AItem.ThreadId <> '' then
    TTask.Run(
      procedure
      begin
        try
          MarkNotificationRead(A, LoadSecret(A.SecretTarget), AItem.ThreadId);
        except
          on E: Exception do
            OutputDebugString(PChar('Vigia: não marcou como lida (' + E.Message + ')'));
        end;
      end);
end;

{ O painel cresce da direita (0 até DetailWidth) e encolhe ao fechar; a lista
  acompanha porque está alinhada ao lado. }
procedure TMainForm.SetDetailVisible(AShow: Boolean);
var
  Target: Integer;
begin
  if AShow = (FDetail.Visible and (FDetail.Width > 0)) then
    Exit;
  Target := ScaleValue(DetailWidth);
  FreeAndNil(FDetailAnim);
  if AShow then
  begin
    FDetail.Width := 0;
    FDetail.Visible := True;
    FDetailAnim := TUIAnimation.Create(0, Target, 220, aeEaseOutCubic);
  end
  else
    FDetailAnim := TUIAnimation.Create(FDetail.Width, 0, 180, aeEaseInCubic);
  FDetailAnim.OnUpdate :=
    procedure(const AValue: Single)
    begin
      FDetail.Width := Round(AValue);
    end;
  FDetailAnim.OnComplete :=
    procedure
    begin
      if FDetail.Width = 0 then
      begin
        FDetail.Visible := False;
        FDetail.Width := ScaleValue(DetailWidth);
      end;
    end;
  FDetailAnim.Start;
end;

procedure TMainForm.ItemsClick(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem);
begin
  // Cabeçalho de grupo: recolhe ou abre.
  if IsGroupRow(AIndex) then
  begin
    if FCollapsed.ContainsKey(FShown[AIndex].Key) then
      FCollapsed.Remove(FShown[AIndex].Key)
    else
      FCollapsed.AddOrSetValue(FShown[AIndex].Key, True);
    TThread.ForceQueue(nil, procedure begin ApplyFilters; end);
    Exit;
  end;
  // Painel aberto acompanha a seleção; fechado, o clique só seleciona.
  if FDetail.Visible and (AIndex >= 0) and (AIndex <= High(FShown)) then
    OpenDetail(FShown[AIndex]);
end;

procedure TMainForm.ItemsDblClick(Sender: TObject; AIndex: Integer; const AItem: TUIVListItem);
begin
  if (AIndex >= 0) and (AIndex <= High(FShown)) and not IsGroupRow(AIndex) then
    OpenDetail(FShown[AIndex]);
end;

{ Botão direito seleciona a linha e monta o menu dela antes do WM_CONTEXTMENU. }
procedure TMainForm.ItemsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  L: TListAccess;
  I: Integer;
  It: TItem;
begin
  if Button <> mbRight then
    Exit;
  L := TListAccess(FItemsList);
  for I := L.FirstVisible to Min(L.LastVisible, High(FShown)) do
    if L.RowRect(I).Contains(PointF(X, Y)) then
    begin
      FItemsList.SelectIndex(I);
      Break;
    end;
  FItemMenu.ClearItems;
  if not SelectedItem(It) then
    Exit;
  FItemMenu.AddItem('detail', 'Ver detalhes', HeroIcon('information-circle'));
  FItemMenu.AddItem('status', 'Mudar status...', HeroIcon('arrow-path'));
  FItemMenu.AddItem('open', 'Abrir no navegador', HeroIcon('arrow-trending-up'));
  FItemMenu.AddItem('copy', 'Copiar chave', HeroIcon('squares-plus'));
  FillActionMenu(It);
  FItemMenu.AddSubmenu('act-sub', 'Ações', FActionMenu, HeroIcon('bolt'));
  FItemMenu.AddSeparator;
  if FMuted.ContainsKey(KeyOf(It)) then
    FItemMenu.AddItem('unmute', 'Reativar avisos', HeroIcon('bolt'))
  else
  begin
    FItemMenu.AddItem('mute-day', 'Silenciar até amanhã', HeroIcon('clock'));
    FItemMenu.AddItem('mute-status', 'Silenciar até mudar status', HeroIcon('signal'));
  end;
  FItemMenu.AddSeparator;
  FillTagMenu(It);
  FItemMenu.AddSubmenu('tag-sub', 'Tag', FTagMenu, HeroIcon('squares-2x2'));
  if IsManual(It) then
  begin
    FItemMenu.AddSeparator;
    FItemMenu.AddItem('unwatch', 'Parar de acompanhar', HeroIcon('x-circle'), True);
  end;
end;

procedure TMainForm.ItemsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  L: TListAccess;
  I, B: Integer;
  A: TAccount;
  Tip, Txt: string;
begin
  L := TListAccess(FItemsList);
  Tip := '';
  for I := L.FirstVisible to Min(L.LastVisible, High(FShown)) do
    if L.RowRect(I).Contains(PointF(X, Y)) then
    begin
      // Selos ficam na 3ª linha (Cy3 = topo + 59, 18 px de altura).
      if (Y >= L.RowRect(I).Top + 50) and (Y <= L.RowRect(I).Top + 68) then
      begin
        B := BadgeIndexAt(X, FShownBadges[I], L.RowRect(I).Left + 14);
        if B >= 0 then
        begin
          Txt := FShownBadges[I][B].Text;
          if Txt = 'Impedida' then
            Tip := 'Marcada com Flagged no Jira: alguém sinalizou um impedimento.'
          else if (Txt.StartsWith('Entrega') or Txt.StartsWith('Prazo')) and
            AccountById(FShown[I].AccountId, A) then
            Tip := Format('Faltam %d dia(s). Laranja com %d, vermelho com %d.',
              [Trunc(DateOf(FShown[I].DueDate) - Date), A.WarnDays, A.CriticalDays])
          else if Txt = 'silenciada' then
            Tip := 'Sem avisos desta issue até o prazo do silêncio. Botão direito para reativar.'
          else if SameText(Txt, FShown[I].Status) then
            Tip := 'Status no ' + IfThen(Pos('#', FShown[I].Key) > 0, 'GitHub', 'Jira') + ': ' + Txt;
        end;
      end;
      Break;
    end;
  if FItemsList.Hint <> Tip then
  begin
    FItemsList.Hint := Tip;
    Application.CancelHint;
  end;
end;

procedure TMainForm.ItemMenuClick(Sender: TObject; const AID: string);
var
  It: TItem;
  A: TAccount;
  T: TTag;
  Lbl: string;
  Names: TArray<string>;
  Idx: Integer;
  On_: Boolean;
begin
  if not SelectedItem(It) then
    Exit;
  if AID = 'detail' then
    OpenDetail(It)
  else if AID = 'open' then
    OpenUrl(It.Url)
  else if AID = 'copy' then
    CopyKey(It)
  else if AID = 'status' then
  begin
    if AccountById(It.AccountId, A) and ChangeStatus(Self, A, It) then
    begin
      TUIToastManager.Show('Status de ' + It.Key + ' alterado', ttSuccess);
      Poll(False);
    end;
  end
  else if AID = 'act-assign' then
  begin
    if AskConfirm(Self, 'Atribuir a mim', Format('Atribuir %s a você no %s?',
      [It.Key, IfThen(Pos('#', It.Key) > 0, 'GitHub', 'Jira')]), 'Atribuir') then
      RunAction(It, It.Key + ' atribuída a você',
        procedure(AAcc: TAccount; AToken: string)
        begin
          AssignToMe(AAcc, AToken, It.Key);
        end);
  end
  else if AID = 'act-label' then
  begin
    Lbl := '';
    if AskText(Self, 'Adicionar label', 'A label entra em ' + It.Key + '.', 'Label', Lbl) then
      RunAction(It, Format('Label "%s" adicionada em %s', [Lbl, It.Key]),
        procedure(AAcc: TAccount; AToken: string)
        begin
          AddLabel(AAcc, AToken, It.Key, Lbl);
        end);
  end
  else if AID = 'act-approve' then
  begin
    if AskConfirm(Self, 'Aprovar PR', 'Enviar aprovação para ' + It.Key + '?', 'Aprovar') then
      RunAction(It, It.Key + ' aprovado',
        procedure(AAcc: TAccount; AToken: string)
        begin
          ApprovePr(AAcc, AToken, It.Key);
        end);
  end
  else if AID = 'act-ci' then
    OpenUrl(It.CiUrl)
  else if AID = 'act-log' then
  begin
    if AccountById(It.AccountId, A) and LogTime(Self, A, It) then
      Poll(False);
  end
  else if AID = 'act-priority' then
  begin
    if not AccountById(It.AccountId, A) then
      Exit;
    try
      Names := FetchPriorities(A, LoadSecret(A.SecretTarget));
    except
      on E: Exception do
      begin
        TUIToastManager.Show('Não carregou as prioridades: ' + E.Message, ttError, 6000);
        Exit;
      end;
    end;
    Idx := -1;
    if AskChoice(Self, 'Mudar prioridade', 'Nova prioridade de ' + It.Key + '.', 'Prioridade', Names, Idx) then
    begin
      Lbl := Names[Idx];
      RunAction(It, Format('Prioridade de %s: %s', [It.Key, Lbl]),
        procedure(AAcc: TAccount; AToken: string)
        begin
          SetPriority(AAcc, AToken, It.Key, Lbl);
        end);
    end;
  end
  else if (AID = 'act-flag') or (AID = 'act-unflag') then
  begin
    Lbl := '';
    On_ := AID = 'act-flag';
    if AskText(Self, IfThen(On_, 'Marcar impedimento', 'Tirar impedimento'),
      IfThen(On_, 'Marca Flagged em ', 'Tira o Flagged de ') + It.Key +
      ' e comenta o motivo na issue.', 'Motivo', Lbl) then
      RunAction(It, IfThen(On_, It.Key + ' marcada como impedida', 'Impedimento de ' + It.Key + ' removido'),
        procedure(AAcc: TAccount; AToken: string)
        begin
          SetImpediment(AAcc, AToken, It.Key, On_, Lbl);
        end);
  end
  else if AID = 'unwatch' then
    Unwatch(It)
  else if AID = 'tag-manage' then
  begin
    if ManageTags(Self, It, False) then
      LoadItems;
  end
  else if AID.StartsWith('tag:') then
  begin
    for T in FTags do
      if T.Id = StrToIntDef(AID.Substring(4), 0) then
      begin
        if T.ByKeyword(It.Title) and not T.HasManual(It.AccountId, It.Key) then
          TUIToastManager.Show(Format('%s entra em "%s" pelo título. Mude as palavras em Gerenciar tags.',
            [It.Key, T.Name]), ttInfo, 5000)
        else
          Store.SetItemTag(T.Id, It.AccountId, It.Key, not T.HasManual(It.AccountId, It.Key));
      end;
    LoadItems;
  end
  else if AID = 'mute-day' then
  begin
    // Amanhã às 8h: o silêncio cobre o resto do dia e a noite.
    Store.Mute(It.AccountId, It.Key, Trunc(Now) + 1 + 8 / 24, '');
    TUIToastManager.Show(It.Key + ' silenciada até amanhã às 8h', ttInfo);
    LoadItems;
  end
  else if AID = 'mute-status' then
  begin
    Store.Mute(It.AccountId, It.Key, 0, It.Status);
    TUIToastManager.Show(It.Key + ' silenciada até sair de "' + It.Status + '"', ttInfo);
    LoadItems;
  end
  else if AID = 'unmute' then
  begin
    Store.Unmute(It.AccountId, It.Key);
    TUIToastManager.Show('Avisos de ' + It.Key + ' reativados', ttSuccess);
    LoadItems;
  end;
end;

procedure TMainForm.NotifyOpenDetail(const AKey: string; AAccountId: Integer);
var
  It: TItem;
begin
  MenuOpenClick(nil);
  if AKey = '*dashboard' then
  begin
    ShowPage(pgDashboard);
    Exit;
  end;
  if AKey = '*teste' then
    Exit;
  if AKey = '*update' then
  begin
    StartUpdate(True);
    Exit;
  end;
  for It in FAll do
    if SameText(It.Key, AKey) and (It.AccountId = AAccountId) then
    begin
      OpenDetail(It);
      Exit;
    end;
end;

{ Clique num card do Dashboard: limpa os filtros, aplica o do card e abre Issues. }
procedure TMainForm.DashboardDrill(Sender: TObject; const ADrill: TDrill);
var
  F: TItemFilter;
  C: TUIFilterChip;
begin
  for F := Low(TItemFilter) to High(TItemFilter) do
    FChips[F].Active := False;
  for C in FTagChips do
    C.Active := False;
  FDrill := Default(TDrill);
  case ADrill.Kind of
    dkMine: FChips[ifMine].Active := True;
    dkFlagged: FChips[ifFlagged].Active := True;
    dkMyPrs: FChips[ifMyPrs].Active := True;
    dkTag:
      for C in FTagChips do
        C.Active := SameText(C.Hint, ADrill.Value);
    dkDueSoon, dkWithDue, dkCategory, dkStatus, dkPrState, dkKind:
      FDrill := ADrill;
    dkRepo:
      begin
        SetRepoFilter(ADrill.Value);
        ShowPage(pgIssues);
        Exit;
      end;
  end;
  FDrillChip.Visible := FDrill.Kind <> dkNone;
  FDrillChip.Caption := FDrill.Caption + '  ✕';
  FDrillChip.Active := True;
  ApplyFilters;
  ShowPage(pgIssues);
end;

procedure TMainForm.DrillChipToggle(Sender: TObject);
begin
  FDrill := Default(TDrill);
  FDrillChip.Visible := False;
  ApplyFilters;
end;

function TMainForm.DrillPass(const AItem: TItem): Boolean;
var
  A: TAccount;
begin
  case FDrill.Kind of
    dkDueSoon:
      Result := (AItem.DueDate > 0) and AccountById(AItem.AccountId, A) and
        (DueTone(AItem.DueDate, A) <> btSuccess);
    dkWithDue: Result := AItem.DueDate > 0;
    dkCategory: Result := CategoryOf(AItem) = FDrill.Value;
    dkStatus: Result := SameText(AItem.Status, FDrill.Value);
    dkKind: Result := (AItem.Url.Contains('/pull/')) = (FDrill.Value = 'pr');
    dkPrState:
      if FDrill.Value = 'CI' then
        Result := MatchText(AItem.CiState, ['FAILURE', 'ERROR'])
      else if FDrill.Value = 'WAITING' then
        Result := (isMine in AItem.Sources) and
          not MatchText(AItem.ReviewState, ['APPROVED', 'CHANGES_REQUESTED'])
      else
        Result := SameText(AItem.ReviewState, FDrill.Value);
  else
    Result := True;
  end;
end;

procedure TMainForm.ViewOpenItem(Sender: TObject; const AItem: TItem);
begin
  OpenDetail(AItem);
end;

procedure TMainForm.DetailClose(Sender: TObject);
begin
  SetDetailVisible(False);
end;

procedure TMainForm.DetailChanged(Sender: TObject);
begin
  Poll(False);
end;

procedure TMainForm.CopyKey(const AItem: TItem);
begin
  Clipboard.AsText := AItem.Key;
  TUIToastManager.Show(AItem.Key + ' copiada', ttSuccess, 1500);
end;

procedure TMainForm.Unwatch(const AItem: TItem);
begin
  Store.RemoveManualKey(AItem.AccountId, AItem.Key);
  FUndoAccount := AItem.AccountId;
  FUndoKey := AItem.Key;
  TUIToastManager.Show('Parei de acompanhar ' + AItem.Key, ttInfo, 6000, 'Desfazer', UndoUnwatch);
  Poll(False);
end;

procedure TMainForm.UndoUnwatch(Sender: TObject);
begin
  if FUndoKey = '' then
    Exit;
  Store.AddManualKey(FUndoAccount, FUndoKey);
  FUndoKey := '';
  Poll(False);
end;

{ Descobre a conta pela forma da chave; se houver mais de uma do mesmo tipo,
  usa a conta do filtro. Confere a issue na API antes de salvar. }
procedure TMainForm.WatchKey(const AText: string);
var
  Key: string;
  IsGitHub: Boolean;
  A, Target: TAccount;
  Count: Integer;
  Token: string;
begin
  Key := NormalizeManualKey(AText, IsGitHub);
  if Key = '' then
  begin
    TUIToastManager.Show('Use PROJ-123 (Jira) ou dono/repo#12 (GitHub)', ttError, 5000);
    Exit;
  end;
  Count := 0;
  for A in FAccounts do
    if (A.Kind = pkGitHub) = IsGitHub then
    begin
      Inc(Count);
      Target := A;
    end;
  if (Count > 1) and (FAccountFilter <> 0) and AccountById(FAccountFilter, A) and
    ((A.Kind = pkGitHub) = IsGitHub) then
  begin
    Target := A;
    Count := 1;
  end;
  if Count = 0 then
  begin
    TUIToastManager.Show('Nenhuma conta ' + IfThen(IsGitHub, 'GitHub', 'Jira') + ' cadastrada', ttError, 5000);
    Exit;
  end;
  if Count > 1 then
  begin
    TUIToastManager.Show('Escolha a conta no seletor do topo', ttError, 5000);
    Exit;
  end;

  Token := LoadSecret(Target.SecretTarget);
  TUIToastManager.Show('Conferindo ' + Key + '...', ttInfo, 2000);
  TTask.Run(
    procedure
    var
      Title, Err: string;
    begin
      try
        Title := CheckItem(Target, Token, Key);
      except
        on E: Exception do
          Err := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          // Tom por valor: dentro desta closure o compilador (22.0) deixa de
          // resolver ttError/ttSuccess depois de UI.TimePicker/UI.PageTransition
          // no uses e acusa "no overloaded version of Queue". 1 = sucesso, 2 = erro.
          if Err <> '' then
          begin
            TUIToastManager.Show(Key + ' não encontrada em ' + Target.Name + ' (' + Err + ')', TUIToastTone(2), 5000);
            Exit;
          end;
          Store.AddManualKey(Target.Id, Key);
          TUIToastManager.Show('Acompanhando ' + Key + ': ' + Title, TUIToastTone(1));
          Poll(False);
        end);
    end);
end;

{ ── Cabeçalho, tray e atalhos ───────────────────────────────────────────── }

{ Rodapé: atalhos de teclado (clicáveis). Mesma altura em todas as abas, então
  o FAB fica sempre no mesmo lugar. }
procedure TMainForm.BuildFooter;
type
  TShortcut = record
    Keys, Caption: string;
    Action: TProc;
  end;
var
  Items: TArray<TShortcut>;
  It: TShortcut;
  K: TUIKbd;
  L: TUILabel;
  N: Integer;

  function Sc(const AKeys, ACaption: string; const AAction: TProc): TShortcut;
  begin
    Result.Keys := AKeys;
    Result.Caption := ACaption;
    Result.Action := AAction;
  end;

begin
  FFooter := NewPanel(FContent, alBottom, 40);
  FFooter.Padding.SetBounds(Sp(UITheme.Tokens.Spacing.S4), 0, Sp(UITheme.Tokens.Spacing.S4), 0);
  Items := [
    Sc('Ctrl+K', 'Buscar, comandos e acompanhar', procedure begin FPalette.Open; end),
    Sc('F5', 'Atualizar', procedure begin Poll(True); end),
    Sc('Ctrl+1-4', 'Abas', procedure begin ShowPage(TPage((Ord(FPage) + 1) mod (Ord(High(TPage)) + 1))); end),
    Sc('Esc', 'Fechar', procedure begin FormKeyDownEsc; end)];
  N := 0;
  for It in Items do
  begin
    K := TUIKbd.Create(Self);
    K.Shortcut := It.Keys;
    K.AlignWithMargins := True;
    K.Margins.SetBounds(IfThen(N = 0, 0, Sp(UITheme.Tokens.Spacing.S4)), 9, 6, 9);
    K.Left := (N * 2 + 1) * 1000;
    K.Align := alLeft;
    K.Parent := FFooter;
    L := TUILabel.Create(Self);
    L.Caption := It.Caption;
    L.Variant := lvMuted;
    L.AutoSize := True;
    L.Cursor := crHandPoint;
    L.Hint := It.Keys;
    L.Tag := N;
    L.Left := (N * 2 + 2) * 1000;
    L.Align := alLeft;
    L.Parent := FFooter;
    // Clicar no texto faz o mesmo que a tecla.
    TClickAccess(L).OnClick := FooterClick;
    FFooterActions := FFooterActions + [It.Action];
    Inc(N);
  end;
  FHoursLabel := TUILabel.Create(Self);
  FHoursLabel.Variant := lvMuted;
  FHoursLabel.AutoSize := True;
  FHoursLabel.Hint := 'Horas que você lançou no Jira (worklog)';
  FHoursLabel.ShowHint := True;
  FHoursLabel.Align := alRight;
  FHoursLabel.Parent := FFooter;
end;

procedure TMainForm.FooterClick(Sender: TObject);
begin
  FFooterActions[TComponent(Sender).Tag]();
end;

procedure TMainForm.FormKeyDownEsc;
var
  Key: Word;
begin
  Key := VK_ESCAPE;
  FormKeyDown(Self, Key, []);
end;

procedure TMainForm.UpdateHeader;
var
  Secs: Integer;
  S: string;
begin
  S := Format('%d itens', [Length(FShown)]);
  if FPolling then
    S := S + '  ·  atualizando...'
  else
  begin
    if FLastPoll > 0 then
      S := S + '  ·  atualizado ' + FormatDateTime('hh:nn', FLastPoll);
    Secs := Max(0, SecondsBetween(FNextPoll, Now));
    S := S + Format('  ·  próxima em %d:%.2d', [Secs div 60, Secs mod 60]);
  end;
  FNextRing.Hint := S;
  // Verde ok, pulsando enquanto busca, vermelho se alguma conta falhou.
  if FPolling then
    FStatusDot.Status := sdBusy
  else if FAccountErrors.Count > 0 then
    FStatusDot.Status := sdError
  else
    FStatusDot.Status := sdOnline;
  FStatusDot.Pulsing := FPolling;
  FNextRing.Indeterminate := FPolling;
  if not FPolling then
    FNextRing.Value := EnsureRange(SecondsBetween(FNextPoll, Now) * 100000 / PollIntervalMs, 0, 100);
  FProgress.Visible := FPolling;
end;

{ Contadores nas abas: não lidos em Issues, contas com erro em Contas.
  ponytail: TUITabs não troca o badge depois de criado; recria as abas. }
procedure TMainForm.UpdateBadges;
var
  Keep: Integer;
begin
  if FTabs = nil then
    Exit;
  // Recriar as abas reinicia a animação do sublinhado: só quando o número muda.
  if Format('%d|%d', [FUnread, FAccountErrors.Count]) = FTabBadges then
    Exit;
  FTabBadges := Format('%d|%d', [FUnread, FAccountErrors.Count]);
  Keep := Ord(FPage);  // a busca recria as abas; a aba aberta continua
  FTabs.OnChange := nil;
  FTabs.RemoveTab(3);  // índice inexistente é ignorado
  FTabs.RemoveTab(2);
  FTabs.RemoveTab(1);
  FTabs.RemoveTab(0);
  FTabs.AddTab(PageTitles[pgDashboard]);
  FTabs.AddTab(PageTitles[pgIssues], FUnread);
  FTabs.AddTab(PageTitles[pgAccounts], FAccountErrors.Count);
  FTabs.AddTab(PageTitles[pgSettings]);
  FTabs.ActiveIndex := Keep;
  FTabs.OnChange := TabChange;
end;

{ Cena do mascote parado conforme a situação: novidade > atrasada > prazo
  perto > normal. Só troca o Lottie quando a cena muda. }
procedure TMainForm.UpdateMascotMood;
var
  F, Tip: string;
begin
  if Now < FNewsUntil then
  begin
    F := 'assistant-news.json';
    Tip := 'Novidade nas issues!';
  end
  else if FOverdue then
  begin
    F := 'assistant-idle-overdue.json';
    Tip := 'Tem issue atrasada';
  end
  else if FDueSoon then
  begin
    F := 'assistant-idle-duesoon.json';
    Tip := 'Prazo chegando';
  end
  else
  begin
    F := 'assistant-idle.json';
    Tip := 'Como posso ajudar?';
  end;
  if F = FMascotFile then
    Exit;
  FMascotFile := F;
  FAssistant.Behaviors.SetBehavior(asIdle, F, 1.0, True, Tip);
end;

procedure TMainForm.ClockTick(Sender: TObject);
begin
  if Visible then
    UpdateHeader;
  UpdateMascotMood;
  // Agendas de minuto em minuto (resumo do dia, fim do "não perturbe").
  if MinuteOf(Now) <> FLastMinuteCheck then
  begin
    FLastMinuteCheck := MinuteOf(Now);
    CheckSchedules;
  end;
end;

function TMainForm.InQuietHours: Boolean;
var
  T, A, B: TDateTime;
begin
  Result := False;
  if Store.GetSetting('dnd_on', '0') <> '1' then
    Exit;
  T := Frac(Now);
  A := TimeSetting('dnd_start', '19:00');
  B := TimeSetting('dnd_end', '08:00');
  if A <= B then
    Result := (T >= A) and (T < B)
  else
    Result := (T >= A) or (T < B);  // atravessa a meia-noite
end;

{ Release nova no GitHub. Automático: uma vez por dia, só na cópia instalada.
  Manual (botão): sempre, e diz o resultado. }
procedure TMainForm.CheckForUpdate(AManual: Boolean);
begin
  if FUpdateBusy then
    Exit;
  if not AManual then
  begin
    if not IsInstalledCopy or (Store.GetSetting('update_mode') = 'off') or
      (Store.GetSetting('update_last') = FormatDateTime('yyyy-mm-dd', Date)) then
      Exit;
    Store.SetSetting('update_last', FormatDateTime('yyyy-mm-dd', Date));
  end;
  FUpdateBusy := True;
  TTask.Run(
    procedure
    var
      Info: TUpdateInfo;
      Found: Boolean;
      Err: string;
    begin
      Found := False;
      try
        Found := FetchLatest(Info);
      except
        on E: Exception do
          Err := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          FUpdateBusy := False;
          if Err <> '' then
          begin
            if AManual then
              TUIToastManager.Show('Não deu para procurar: ' + Err, ttError, 6000);
            Exit;
          end;
          if not Found then
          begin
            if AManual then
              TUIToastManager.Show('Você já está na versão mais nova (' + AppVersion + ')', ttSuccess);
            Exit;
          end;
          FUpdate := Info;
          FUpdateItem.Caption := 'Atualizar para ' + Info.Version;
          FUpdateItem.Visible := True;
          FUpdateBtn.Caption := 'Atualizar para ' + Info.Version;
          if (Store.GetSetting('update_mode') = 'auto') and not AManual and not Visible then
            StartUpdate(False)
          else
            Notify('Vigia ' + Info.Version + ' disponível', 'Você está na ' + AppVersion +
              '. Clique para atualizar; o Vigia fecha e volta sozinho.', '', stInfo, '*update');
        end);
    end);
end;

{ Baixa, confere o hash, roda o instalador e sai. O instalador reabre o Vigia. }
procedure TMainForm.StartUpdate(AShow: Boolean);
var
  Info: TUpdateInfo;
begin
  if FUpdateBusy or (FUpdate.Version = '') then
    Exit;
  if not IsInstalledCopy then
  begin
    TUIToastManager.Show('Esta cópia não foi instalada pelo instalador. Baixe a ' + FUpdate.Version +
      ' na página de releases.', ttWarning, 6000);
    Exit;
  end;
  Info := FUpdate;
  FUpdateBusy := True;
  TUIToastManager.Show('Baixando o Vigia ' + Info.Version + '...', ttInfo);
  TTask.Run(
    procedure
    var
      Path, Err: string;
    begin
      try
        Path := DownloadUpdate(Info);
      except
        on E: Exception do
          Err := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          FUpdateBusy := False;
          if Err <> '' then
          begin
            TUIToastManager.Show('Atualização falhou: ' + Err, ttError, 8000);
            Exit;
          end;
          try
            RunInstaller(Path, AShow);
          except
            on E: Exception do
            begin
              TUIToastManager.Show('Não abriu o instalador: ' + E.Message, ttError, 8000);
              Exit;
            end;
          end;
          MenuExitClick(nil);
        end);
    end);
end;

procedure TMainForm.UpdateMenuClick(Sender: TObject);
begin
  StartUpdate(True);
end;

procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  if FUpdate.Version <> '' then
    StartUpdate(True)
  else
    CheckForUpdate(True);
end;

procedure TMainForm.CheckSchedules;
var
  It: TItem;
  A: TAccount;
  Red, Orange, Flagged, Comments: Integer;
  E: TEvent;
  Keys: string;
begin
  // Fim do silêncio: entrega o que ficou guardado.
  if (FPending <> nil) and not InQuietHours then
  begin
    if Length(FPending) <= 3 then
      for E in FPending do
        Notify(E.Title, E.Body, E.Url, EventTone(E.Kind), E.Key, E.AccountId)
    else
    begin
      Keys := '';
      for E in FPending do
        if not ContainsText(Keys, E.Key) then
          Keys := Keys + IfThen(Keys <> '', ', ') + E.Key;
      Notify(Format('Vigia · %d avisos durante o silêncio', [Length(FPending)]), Keys, '', stPrimary,
        '*dashboard');
    end;
    FPending := nil;
  end;

  if not InQuietHours then
    RunAutoAi;
  if FLastPoll > 0 then
    CheckForUpdate(False);

  // Resumo do dia, uma vez por dia a partir do horário escolhido.
  if (Store.GetSetting('summary_on', '1') = '1') and (FLastPoll > 0) and
    (Frac(Now) >= TimeSetting('summary_time', '09:00')) and
    (Store.GetSetting('summary_last') <> FormatDateTime('yyyy-mm-dd', Date)) and not InQuietHours then
  begin
    Store.SetSetting('summary_last', FormatDateTime('yyyy-mm-dd', Date));
    Red := 0;
    Orange := 0;
    Flagged := 0;
    for It in FAll do
    begin
      if It.Flagged then
        Inc(Flagged);
      if (It.DueDate > 0) and AccountById(It.AccountId, A) then
        case DueTone(It.DueDate, A) of
          btError: Inc(Red);
          btWarning: Inc(Orange);
        end;
    end;
    Comments := Store.CountEvents(ekComment, 24) + Store.CountEvents(ekMention, 24);
    if Store.GetSetting('ai_daily') = '1' then
    begin
      AiAsk(BuildAiContext, 'Escreva o resumo de bom dia em até 4 frases curtas: o que vence, o que está ' +
        'impedido, o que mudou desde ontem e por onde começar. Cite as chaves. Sem markdown.', True,
        procedure(AText: string)
        begin
          Notify('Bom dia · resumo do Vigia', AText, '', stPrimary, '*dashboard');
        end,
        procedure(AErr: string)
        begin
          Notify('Bom dia · resumo do Vigia', Format('%d vencendo ou vencidas, %d chegando, %d impedidas. ' +
            '(IA indisponível: %s)', [Red, Orange, Flagged, AErr]), '', stPrimary, '*dashboard');
        end);
      Exit;
    end;
    Notify('Bom dia · resumo do Vigia', Format('%d vencendo ou vencidas, %d chegando, %d impedidas, ' +
      '%d comentário(s) nas últimas 24 h.', [Red, Orange, Flagged, Comments]), '', stPrimary, '*dashboard');
  end;
end;

procedure TMainForm.UpdateTrayIcon;
begin
  FTray.Icon.Handle := MakeTrayIcon(FUnread, FOverdue);  // TIcon assume e libera o handle
  if FUnread = 0 then
    Icon.Handle := MakeTrayIcon(0, False);
end;

procedure TMainForm.AutostartClick(Sender: TObject);
begin
  SetAutostart(not FAutostartItem.Checked);
  FAutostartItem.Checked := AutostartEnabled;
  FAutostartToggle.Checked := FAutostartItem.Checked;
end;

procedure TMainForm.AlertDismiss(Sender: TObject);
begin
  FAlert.Visible := False;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  It: TItem;
begin
  case Key of
    VK_F5:
      Poll(True);
    VK_ESCAPE:
      if FDetail.Visible then
        SetDetailVisible(False)
      else
        Hide;
    Ord('F'):
      if ssCtrl in Shift then
        FPalette.Open
      else
        Exit;
    Ord('C'):
      if (ssCtrl in Shift) and FItemsList.Focused and SelectedItem(It) then
        CopyKey(It)
      else
        Exit;
    VK_RETURN:
      if FItemsList.Focused and SelectedItem(It) then
        OpenDetail(It)
      else
        Exit;
    Ord('1')..Ord('4'):
      if ssCtrl in Shift then
        ShowPage(TPage(Key - Ord('1')))
      else
        Exit;
  else
    Exit;
  end;
  Key := 0;
end;

{ ── Busca e avisos ──────────────────────────────────────────────────────── }

procedure TMainForm.Notify(const ATitle, ABody: string; const AUrl: string;
  ATone: TUISemanticTone; const AKey: string; AAccountId: Integer);
var
  N: TNotification;
  E: TEvent;
begin
  FLastUrl := AUrl;
  // "Não perturbe": guarda e entrega no fim do silêncio (CheckSchedules).
  if InQuietHours and (AKey <> '*teste') then
  begin
    E := Default(TEvent);
    E.Title := ATitle;
    E.Body := ABody;
    E.Url := AUrl;
    E.Key := AKey;
    E.AccountId := AAccountId;
    E.Kind := ekComment;
    FPending := FPending + [E];
    Exit;
  end;
  // Padrão: aviso da ComponentesUI no canto da tela. 'windows' usa o toast do sistema.
  if Store.GetSetting('notify_style', 'vigia') = 'vigia' then
  begin
    TNotifyManager.Show(ATitle, ABody, AUrl, ATone, AKey, AAccountId,
      StrToIntDef(Store.GetSetting('notify_seconds'), DefaultNotifySeconds) * 1000);
    Exit;
  end;
  Inc(FToastSeq);
  // Toast do Windows. Se a plataforma recusar, cai no balão da tray.
  try
    N := FNotifier.CreateNotification;
    try
      N.Name := 'vigia-' + IntToStr(FToastSeq);
      N.Title := ATitle;
      N.AlertBody := ABody;
      if AUrl <> '' then
        FToastUrls.AddOrSetValue(N.Name, AUrl);
      FNotifier.PresentNotification(N);
    finally
      N.Free;
    end;
  except
    FTray.BalloonTitle := ATitle;
    FTray.BalloonHint := ABody;
    FTray.ShowBalloonHint;
  end;
end;

procedure TMainForm.ToastClicked(Sender: TObject; ANotification: TNotification);
var
  Url: string;
begin
  if FToastUrls.TryGetValue(ANotification.Name, Url) then
    OpenUrl(Url);
end;

procedure TMainForm.BalloonClick(Sender: TObject);
begin
  OpenUrl(FLastUrl);
end;

procedure TMainForm.RefreshClick(Sender: TObject);
begin
  Poll(True);
end;

procedure TMainForm.TimerTick(Sender: TObject);
begin
  FTimer.Interval := PollIntervalMs;
  Poll(False);
end;

{ Rede numa task; diff, snapshot e toast de volta na thread de UI (FireDAC não é
  compartilhado entre threads). AManual = veio do usuário: mostra "nada novo". }
procedure TMainForm.Poll(AManual: Boolean);
var
  Jobs: TArray<TPollResult>;
  Job: TPollResult;
  A: TAccount;
  Global: Integer;
begin
  if FPolling then
    Exit;
  Jobs := nil;
  Global := StrToIntDef(Store.GetSetting('poll_minutes'), DefaultPollMinutes);
  for A in Store.ListAccounts do
    if A.Enabled and (AManual or FPollAll or
      (Now - Store.LastPoll(A.Id) >= (IfThen(A.PollMinutes > 0, A.PollMinutes, Global) - 0.5) / MinsPerDay)) then
    begin
      Job := Default(TPollResult);
      Job.Account := A;
      Job.ManualKeys := Store.ListManualKeys(A.Id);
      Jobs := Jobs + [Job];
    end;
  FPollAll := False;
  if Jobs = nil then
  begin
    if AManual then
      TUIToastManager.Show('Nenhuma conta ligada', ttWarning);
    LoadItems;
    // Nenhuma conta na vez: o relógio segue.
    FTimer.Enabled := False;
    FTimer.Interval := PollIntervalMs;
    FTimer.Enabled := True;
    FNextPoll := Now + PollIntervalMs / MSecsPerDay;
    Exit;
  end;
  FPolling := True;
  // Reinicia o relógio: a busca manual empurra a automática.
  FTimer.Enabled := False;
  FTimer.Interval := PollIntervalMs;
  FTimer.Enabled := True;
  FNextPoll := Now + PollIntervalMs / MSecsPerDay;
  FTray.Hint := 'Vigia · atualizando...';
  ApplyFilters;
  UpdateHeader;

  TTask.Run(
    procedure
    var
      I: Integer;
      HToday, HWeek, T, W: Double;
      HasJira: Boolean;
    begin
      HToday := 0;
      HWeek := 0;
      HasJira := False;
      for I := 0 to High(Jobs) do
      begin
        try
          Jobs[I].Items := FetchItems(Jobs[I].Account, LoadSecret(Jobs[I].Account.SecretTarget),
            Jobs[I].ManualKeys, Jobs[I].Me);
        except
          on E: Exception do
            Jobs[I].Error := E.Message;
        end;
        // ponytail: soma só as contas Jira desta rodada; com várias contas Jira em
        // intervalos diferentes o total fica parcial até a próxima busca de todas.
        if (Jobs[I].Account.Kind <> pkGitHub) and (Jobs[I].Error = '') then
          try
            FetchWeekHours(Jobs[I].Account, LoadSecret(Jobs[I].Account.SecretTarget), T, W);
            HToday := HToday + T;
            HWeek := HWeek + W;
            HasJira := True;
          except
            on E: Exception do
              OutputDebugString(PChar('Vigia: horas da semana (' + E.Message + ')'));
          end;
      end;

      TThread.Queue(nil,
        procedure
        var
          PR: TPollResult;
          Events, All: TEvents;
          E: TEvent;
          Items: TItems;
          Baseline: Boolean;
          Errors, Keys, Status: string;
          Kept: TEvents;
          It: TItem;
          Changed: TArray<string>;
          Before: TDictionary<string, Boolean>;
        begin
          All := nil;
          Changed := nil;
          if HasJira then
          begin
            FHoursToday := HToday;
            FHoursWeek := HWeek;
            FHoursLabel.Caption := Format('Lançado: %.1fh hoje · %.1fh na semana', [HToday, HWeek]);
          end;
          // Chaves antes da busca: o que não estava aqui entra deslizando.
          Before := TDictionary<string, Boolean>.Create;
          for It in FAll do
            Before.AddOrSetValue(KeyOf(It), True);
          Errors := '';
          try
            for PR in Jobs do
            begin
              if PR.Error <> '' then
              begin
                FAccountErrors.AddOrSetValue(PR.Account.Id, PR.Error);
                Errors := Errors + PR.Account.Name + ': ' + PR.Error + sLineBreak;
                Continue;
              end;
              FAccountErrors.Remove(PR.Account.Id);
              Items := PR.Items;
              Baseline := not Store.HasSnapshot(PR.Account.Id);
              Events := DiffItems(Store.LoadSnapshot(PR.Account.Id), Items, PR.Account,
                PR.Me, Date, Baseline);
              Store.SaveSnapshot(PR.Account.Id, Items);
              Store.AddEvents(Events);
              if Baseline then
                Notify('Vigia · ' + PR.Account.Name,
                  Format('Acompanhando %d itens. Aviso o que mudar daqui pra frente.', [Length(Items)]));
              All := All + FilterEvents(Events, PR.Account.Events);
            end;

            // Silenciadas não avisam (o histórico continua gravando).
            Kept := nil;
            for E in All do
            begin
              Status := '';
              for PR in Jobs do
                for It in PR.Items do
                  if (It.AccountId = E.AccountId) and SameText(It.Key, E.Key) then
                    Status := It.Status;
              if not Store.IsMuted(E.AccountId, E.Key, Status) then
                Kept := Kept + [E];
            end;
            All := Kept;
            Changed := nil;
            for E in All do
              Changed := Changed + [IntToStr(E.AccountId) + '|' + E.Key.ToUpper];

            if All <> nil then
            begin
              // Novidade: o mascote comemora uns segundos.
              FNewsUntil := Now + 5 / SecsPerDay;
              UpdateMascotMood;
            end;
            for E in All do
              if E.Kind = ekCiFailed then
                for PR in Jobs do
                  for It in PR.Items do
                    if (It.AccountId = E.AccountId) and SameText(It.Key, E.Key) then
                      ExplainCiFailure(It);
            if Length(All) <= MaxToastsPerPoll then
              for E in All do
                Notify(E.Title, E.Body, E.Url, EventTone(E.Kind), E.Key, E.AccountId)
            else
            begin
              Keys := '';
              for E in All do
                if not ContainsText(Keys, E.Key) then
                  Keys := Keys + IfThen(Keys <> '', ', ') + E.Key;
              Notify(Format('Vigia · %d novidades', [Length(All)]), Keys, '', stPrimary);
            end;

            // Janela aberta e ativa: o usuário já está vendo, não conta como não lido.
            if not (Visible and Application.Active) then
              Inc(FUnread, Length(All));

            FAlert.Title := 'Falha na busca';
            FAlert.Message_ := Errors.Trim;
            FAlert.Visible := Errors <> '';
            if AManual and (All = nil) and (Errors = '') then
              TUIToastManager.Show('Nada novo', ttInfo, 2000);

            FLastPoll := Now;
          finally
            FPolling := False;
            ReloadAccounts;
            LoadItems;
            FNewKeys.Clear;
            if Before.Count > 0 then
              for It in FAll do
                if not Before.ContainsKey(KeyOf(It)) then
                  FNewKeys.AddOrSetValue(KeyOf(It), True);
            Before.Free;
            FlashChanges(Changed);
            UpdateBadges;
            FTray.Hint := Format('Vigia · %d itens · %s%s', [Length(FAll),
              FormatDateTime('hh:nn', FLastPoll), IfThen(Errors <> '', ' · com erro', '')]);
          end;
        end);
    end);
end;

{ ── Janela e tray ───────────────────────────────────────────────────────── }

procedure TMainForm.TrayDblClick(Sender: TObject);
begin
  MenuOpenClick(Sender);
end;

procedure TMainForm.MenuOpenClick(Sender: TObject);
begin
  FUnread := 0;
  UpdateTrayIcon;
  UpdateBadges;
  UpdateHeader;
  AnimateWindowTo(True);
end;

procedure TMainForm.MenuExitClick(Sender: TObject);
begin
  ExitRequested := True;
  Close;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Fechar a janela só esconde (com esmaecer); sair é pelo menu da tray.
  CanClose := ExitRequested;
  if not CanClose then
    AnimateWindowTo(False);
end;

{ Abre esmaecendo e subindo 12 px; fecha descendo e sumindo, depois Hide. }
procedure TMainForm.AnimateWindowTo(AShow: Boolean);
const
  Lift = 12;
  OpenMs = 220;
  CloseMs = 160;
begin
  if FWinAnim = nil then
  begin
    FWinAnim := TUIAnimation.Create(0, 1, OpenMs, aeEaseOutCubic);
    FWinAnim.OnUpdate :=
      procedure(const AValue: Single)
      begin
        AlphaBlendValue := EnsureRange(Round(255 * AValue), 0, 255);
        Top := FWinTop + Round((1 - AValue) * ScaleValue(Lift));
      end;
    FWinAnim.OnComplete :=
      procedure
      begin
        if FWinClosing then
        begin
          FWinClosing := False;
          // Na bandeja ninguém vê o mascote: escondido, o Lottie para de animar.
          FAssistant.Visible := False;
          Hide;
          Top := FWinTop;
          AlphaBlendValue := 255;
        end;
      end;
  end;
  if AShow and Visible and not FWinClosing and not FWinAnim.Running then
  begin
    // Já aberta: só traz para a frente, sem piscar transparente.
    WindowState := wsNormal;
    Application.BringToFront;
    Exit;
  end;
  if AShow then
  begin
    // No meio de uma animação o Top tem o deslocamento: mantém o de repouso.
    if (FWinAnim = nil) or not FWinAnim.Running then
      FWinTop := Top;
    FWinClosing := False;
    if not Visible then
    begin
      AlphaBlendValue := 0;
      Top := FWinTop + ScaleValue(Lift);
    end;
    FAssistant.Visible := True;
    Show;
    WindowState := wsNormal;
    Application.BringToFront;
    // Parte de onde está (abrir no meio de um fechar) ou do zero.
    if FWinAnim.Running then
      FWinAnim.FromValue := FWinAnim.Value
    else
      FWinAnim.FromValue := 0;
    FWinAnim.ToValue := 1;
    FWinAnim.Duration := OpenMs;
    FWinAnim.Start;
  end
  else if Visible and not FWinClosing then
  begin
    if not FWinAnim.Running then
      FWinTop := Top;
    FWinClosing := True;
    if FWinAnim.Running then
      FWinAnim.FromValue := FWinAnim.Value
    else
      FWinAnim.FromValue := 1;
    FWinAnim.ToValue := 0;
    FWinAnim.Duration := CloseMs;
    FWinAnim.Start;
  end;
end;

procedure TMainForm.ThemeSwapToggle(Sender: TObject);
var
  Theme: string;
begin
  Theme := IfThen(FThemeSwap.Checked, 'dark', 'light');
  // Escolha explícita vale para este usuário; sem ela, segue o Windows.
  Store.SetSetting('theme', Theme);
  // O círculo do reveal sai do centro do sol/lua, não do cursor.
  UITheme.SetThemeReveal(Theme, TPointF.Create(FThemeSwap.ClientToScreen(
    Point(FThemeSwap.Width div 2, FThemeSwap.Height div 2))), Self);
end;

procedure TMainForm.ThemeChanged(Sender: TObject; AMode: TUIThemeMode);
begin
  if FApplyingSize then
    Exit;
  ApplyCompactSize;
  FThemeSwap.Checked := UITheme.IsDark;
  FThemeSelect.OnChange := nil;
  FThemeSelect.ItemIndex := IndexText(Store.GetSetting('theme'), ['', 'light', 'dark']);
  FThemeSelect.OnChange := GeneralSettingChange;
  ApplyThemeColors;
  FDetail.ApplyTheme;
  // Quadro e gráficos guardam cores do tema na criação.
  UpdateViews;
end;

initialization
  WM_VIGIA_SHOW := RegisterWindowMessage(ShowMessageName);

end.
