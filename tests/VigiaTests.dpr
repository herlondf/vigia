program VigiaTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Vigia.Model in '..\src\Vigia.Model.pas',
  Vigia.Secrets in '..\src\Vigia.Secrets.pas',
  Vigia.Store in '..\src\Vigia.Store.pas',
  Vigia.Providers in '..\src\Vigia.Providers.pas',
  Vigia.Diff in '..\src\Vigia.Diff.pas',
  Vigia.TrayIcon in '..\src\Vigia.TrayIcon.pas',
  Vigia.Update in '..\src\Vigia.Update.pas',
  Vigia.Backup in '..\src\Vigia.Backup.pas',
  Vigia.I18n in '..\src\Vigia.I18n.pas',
  Vigia.I18n.En in '..\src\Vigia.I18n.En.pas',
  Winapi.Windows,
  Vcl.Graphics,
  System.Types,
  System.JSON,
  System.DateUtils,
  System.StrUtils,
  System.Skia;

procedure Check(ACond: Boolean; const AMsg: string);
begin
  if not ACond then
    raise Exception.Create('FALHOU: ' + AMsg);
  Writeln('ok  ', AMsg);
end;

procedure TestSecrets;
const
  T = 'Vigia:test-selfcheck';
begin
  SaveSecret(T, 'user', 'tok-ção-123');
  Check(LoadSecret(T) = 'tok-ção-123', 'segredo volta igual (com acento)');
  DeleteSecret(T);
  Check(LoadSecret(T) = '', 'segredo apagado');
end;

procedure TestStore;
var
  Db: string;
  S: TStore;
  A: TAccount;
  L: TArray<TAccount>;
begin
  Db := TPath.Combine(TPath.GetTempPath, 'vigia-test.db');
  if TFile.Exists(Db) then
    TFile.Delete(Db);
  S := TStore.Create(Db);
  try
    A := NewAccount(pkJiraCloud);
    A.Name := 'Teste';
    A.Login := 'a@b.c';
    A.Events := [ekComment, ekOverdue];
    S.SaveAccount(A);
    Check(A.Id > 0, 'insert devolve id');
    L := S.ListAccounts;
    Check((Length(L) = 1) and (L[0].Events = [ekComment, ekOverdue]) and
      (L[0].Kind = pkJiraCloud) and (L[0].Login = 'a@b.c'), 'conta volta igual');
    A.Enabled := False;
    S.SaveAccount(A);
    Check(not S.ListAccounts[0].Enabled, 'update grava');
    S.AddManualKey(A.Id, 'PRJ-1');
    S.AddManualKey(A.Id, 'prj-1');
    S.AddManualKey(A.Id, 'o/r#2');
    Check(Length(S.ListManualKeys(A.Id)) = 2, 'manual sem duplicar (maiúscula/minúscula)');
    S.RemoveManualKey(A.Id, 'PRJ-1');
    Check(Length(S.ListManualKeys(A.Id)) = 1, 'manual remove');
    // Silenciar: por prazo e até mudar de status.
    S.Mute(A.Id, 'PRJ-9', Now + 1, '');
    Check(S.IsMuted(A.Id, 'PRJ-9', 'Aberto'), 'silenciada até amanhã');
    S.Mute(A.Id, 'PRJ-9', Now - 1, '');
    Check(not S.IsMuted(A.Id, 'PRJ-9', 'Aberto'), 'prazo do silêncio passou: solta');
    S.Mute(A.Id, 'PRJ-8', 0, 'Aberto');
    Check(S.IsMuted(A.Id, 'PRJ-8', 'Aberto'), 'silenciada enquanto o status não muda');
    Check(not S.IsMuted(A.Id, 'PRJ-8', 'Em teste'), 'status mudou: solta');
    Check(not S.IsMuted(A.Id, 'PRJ-8', 'Aberto'), 'depois de soltar não volta sozinha');
    S.DeleteAccount(A.Id);
    Check(Length(S.ListAccounts) = 0, 'delete remove');
    Check(Length(S.ListManualKeys(A.Id)) = 0, 'delete leva os manuais junto');
  finally
    S.Free;
  end;
end;


function Obj(const S: string): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(S) as TJSONObject;
  if Result = nil then
    raise Exception.Create('JSON de teste inválido');
end;

procedure TestDates;
begin
  Check(ParseIsoDate('') = 0, 'data vazia = 0');
  Check(ParseIsoDate('2026-10-03') = EncodeDate(2026, 10, 3), 'duedate do Jira');
  Check(SameDateTime(ParseIsoDate('2026-10-01T12:00:00Z'), EncodeDateTime(2026, 10, 1, 12, 0, 0, 0)),
    'ISO com Z');
  Check(SameDateTime(ParseIsoDate('2026-10-01T09:00:00.000-0300'), EncodeDateTime(2026, 10, 1, 12, 0, 0, 0)),
    'ISO do Jira com -0300 vira UTC');
end;

procedure TestGitHub;
var
  J: TJSONObject;
  It: TItem;
begin
  J := Obj('{"number":12,"title":"Bug X","html_url":"https://github.com/o/r/issues/12",' +
    '"state":"open","repository_url":"https://api.github.com/repos/o/r",' +
    '"assignees":[{"login":"ana"}],"comments":3,"updated_at":"2026-10-01T12:00:00Z",' +
    '"milestone":{"due_on":"2026-10-05T07:00:00Z"}}');
  try
    It := ParseGitHubIssue(J, 7);
    Check((It.Key = 'o/r#12') and (It.AccountId = 7), 'GitHub key');
    Check((It.Assignee = 'ana') and (It.CommentCount = 3) and (It.Status = 'open'), 'GitHub campos');
    Check(Trunc(It.DueDate) = EncodeDate(2026, 10, 5), 'GitHub prazo pelo milestone');
  finally
    J.Free;
  end;
  J := Obj('{"number":1,"title":"t","repository_url":"https://api.github.com/repos/a/b","milestone":null}');
  try
    Check(ParseGitHubIssue(J, 1).DueDate = 0, 'GitHub milestone null = sem prazo');
  finally
    J.Free;
  end;
  Check(GitHubKeyFromApiUrl('https://api.github.com/repos/o/r/pulls/9') = 'o/r#9', 'key da notification (PR)');
end;

procedure TestJiraServer;
var
  J: TJSONObject;
  A: TAccount;
  Me: TIdentity;
  It: TItem;
begin
  A := NewAccount(pkJiraServer);
  A.Id := 2;
  A.BaseUrl := 'https://jira.exemplo.com/';
  Me.Id := 'ana.lima';
  J := Obj('{"key":"APP-10","fields":{"summary":"Nota","status":{"name":"Em andamento"},' +
    '"assignee":{"name":"ana.lima","displayName":"Ana"},"duedate":"2026-10-03",' +
    '"updated":"2026-10-01T09:00:00.000-0300",' +
    '"comment":{"total":2,"comments":[{"author":{"name":"x"},"body":"a"},' +
    '{"author":{"name":"maria"},"body":"oi [~ana.lima], veja"}]}}}');
  try
    It := ParseJiraIssue(J, A, Me);
    Check(It.Url = 'https://jira.exemplo.com/browse/APP-10', 'Jira URL sem barra dupla');
    Check(isAssigned in It.Sources, 'Jira Server: associado a mim');
    Check((It.Status = 'Em andamento') and (It.DueDate = EncodeDate(2026, 10, 3)), 'Jira Server campos');
    Check((It.CommentCount = 2) and (It.LastCommentBy = 'maria'), 'Jira Server último comentário');
    Check(It.MentionsMe, 'Jira Server menção [~usuario]');
  finally
    J.Free;
  end;
end;

procedure TestJiraFlagAndDueField;
var
  J: TJSONObject;
  A: TAccount;
  Me: TIdentity;
  It: TItem;
begin
  A := NewAccount(pkJiraServer);
  A.BaseUrl := 'https://jira.exemplo.com';
  J := Obj('{"key":"P-9","fields":{"summary":"S","status":{"name":"Em Teste",' +
    '"statusCategory":{"key":"indeterminate"}},"duedate":"2026-12-31",' +
    '"customfield_10304":[{"value":"Impediment"}],"customfield_11039":"2026-10-13",' +
    '"updated":"2026-10-01T12:00:00.000+0000"}}');
  try
    It := ParseJiraIssue(J, A, Me, 'customfield_10304', 'customfield_11039');
    Check(It.Flagged and (It.StatusCategory = 'indeterminate'), 'Flagged e categoria do status');
    Check(It.DueDate = EncodeDate(2026, 10, 13), 'prazo vem do campo configurado, não do duedate');
    It := ParseJiraIssue(J, A, Me, '', '');
    Check(not It.Flagged and (It.DueDate = EncodeDate(2026, 12, 31)), 'sem campo: sem flag e usa duedate');
    It := ParseJiraIssue(J, A, Me, 'customfield_10304', 'customfield_99999');
    Check(It.DueDate = 0, 'campo configurado vazio na issue = sem prazo (não cai no duedate)');
  finally
    J.Free;
  end;
end;

procedure TestJiraCloud;
var
  J: TJSONObject;
  A: TAccount;
  Me: TIdentity;
  It: TItem;
begin
  A := NewAccount(pkJiraCloud);
  A.BaseUrl := 'https://x.atlassian.net';
  Me.Id := 'acc-1';
  J := Obj('{"key":"PRJ-5","fields":{"summary":"S","status":{"name":"To Do"},' +
    '"assignee":{"accountId":"acc-2","displayName":"Outro"},"duedate":null,' +
    '"updated":"2026-10-01T12:00:00.000+0000",' +
    '"comment":{"total":1,"comments":[{"author":{"accountId":"acc-2"},"body":' +
    '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Olá "},' +
    '{"type":"mention","attrs":{"id":"acc-1","text":"@Ana"}},{"type":"text","text":" pode ver?"}]}]}}]}}}');
  try
    It := ParseJiraIssue(J, A, Me);
    Check(not (isAssigned in It.Sources) and (It.DueDate = 0), 'Jira Cloud: não associado, sem prazo');
    Check(It.LastCommentText = 'Olá @Ana pode ver?', 'ADF vira texto: "' + It.LastCommentText + '"');
    Check(It.MentionsMe and (It.LastCommentBy = 'acc-2'), 'Jira Cloud menção por accountId');
  finally
    J.Free;
  end;
end;

function MkItem(const AKey, AStatus: string; AComments: Integer; const ABy: string;
  ASources: TItemSources; ADue: TDateTime = 0): TItem;
begin
  Result := Default(TItem);
  Result.AccountId := 1;
  Result.Key := AKey;
  Result.Title := 'T ' + AKey;
  Result.Status := AStatus;
  Result.CommentCount := AComments;
  Result.LastCommentBy := ABy;
  Result.Sources := ASources;
  Result.DueDate := ADue;
end;

function Kinds(const AEvents: TEvents): string;
var
  E: TEvent;
begin
  Result := '';
  for E in AEvents do
    Result := Result + E.Key + ':' + EventNames[E.Kind] + ';';
end;

procedure TestCleanComment;
begin
  Check(CleanCommentText('est&aacute; <b>ok</b> &amp; r&aacute;pido &#233;') = 'está ok & rápido é',
    'comentário: entidades e tags');
  Check(WikiToText('h3. Resultado' + sLineBreak + '||Q||tempo||' + sLineBreak + '|Q1|0,05 ms|') =
    'Resultado' + sLineBreak + 'Q · tempo' + sLineBreak + 'Q1 · 0,05 ms', 'wiki: título e tabela');
  Check(WikiToText('índice {{idx_pedido}} *não* seletivo, ver [doc|http://x] e [~joao]') =
    'índice idx_pedido não seletivo, ver doc e @joao', 'wiki: código, negrito, link, menção');
  Check(WikiToText('* um' + sLineBreak + '* dois') = '• um' + sLineBreak + '• dois', 'wiki: lista');
  Check(MarkdownToText('## Erro' + sLineBreak + '- veja **isto** em [doc](http://x) e `cfg`') =
    'Erro' + sLineBreak + '• veja isto em doc e cfg', 'markdown: título, lista, negrito, link, código');
  Check(MarkdownToText('```' + sLineBreak + 'x := 1;' + sLineBreak + '```') = 'x := 1;',
    'markdown: bloco de código sem as cercas');
end;

procedure TestTags;
var
  T: TTag;
  It: TItem;
begin
  T := Default(TTag);
  T.Name := 'Pagamentos';
  T.Keywords := 'pagamento, check-out';
  It := Default(TItem);
  It.AccountId := 1;
  It.Key := 'APP-1';
  It.Title := 'Erro no Check-Out de pedidos pendentes';
  Check(T.Matches(It), 'tag: palavra no título, sem caixa');
  It.Title := 'Tela de configurações';
  Check(not T.Matches(It), 'tag: título sem palavra fica fora');
  T.Manual := [ItemTagKey(1, 'app-1')];
  Check(T.Matches(It), 'tag: marcação manual, chave sem caixa');
  T.Keywords := ' , ';
  T.Manual := nil;
  Check(not T.Matches(It), 'tag: palavra vazia não casa com tudo');
  T.Keywords := 'PIX;configura';
  Check(T.Matches(It), 'tag: ponto e vírgula também separa');
end;

procedure TestPrsAndFilter;
var
  A: TAccount;
  Me: TIdentity;
  Old, New: TItems;
  Ev: TEvents;
begin
  A := NewAccount(pkGitHub);
  A.Id := 2;
  A.Name := 'gh';
  Me.Id := 'eu';
  Old := [MkItem('o/app#1', 'open', 0, '', [isMine])];
  Old[0].ReviewState := 'REVIEW_REQUIRED';
  Old[0].CiState := 'PENDING';
  New := Copy(Old);
  New[0].ReviewState := 'APPROVED';
  New[0].CiState := 'FAILURE';
  Ev := DiffItems(Old, New, A, Me, Date, False);
  Check(Kinds(Ev) = 'o/app#1:PR aprovado;o/app#1:CI falhou;', 'PR: aprovado e CI falhou: ' + Kinds(Ev));
  Old := New;
  New := Copy(Old);
  New[0].ReviewState := 'CHANGES_REQUESTED';
  Ev := DiffItems(Old, New, A, Me, Date, False);
  Check(Kinds(Ev) = 'o/app#1:Mudanças pedidas;', 'PR: mudanças pedidas, CI não repete: ' + Kinds(Ev));

  A.IncludeList := 'o, x/lib';
  A.ExcludeList := 'o/velho';
  Check(ItemAllowed(A, 'o/app#1') and ItemAllowed(A, 'x/lib#2'), 'filtro: dono e repo incluídos');
  Check(not ItemAllowed(A, 'x/outro#3'), 'filtro: fora do incluir');
  Check(not ItemAllowed(A, 'o/velho#4'), 'filtro: ignorar vence o incluir');
  A := NewAccount(pkJiraServer);
  A.ExcludeList := 'ABC';
  Check(ItemAllowed(A, 'APP-1') and not ItemAllowed(A, 'ABC-9'), 'filtro: projeto do Jira');
end;

{ Backup sem tokens (o teste não toca no Credential Manager). }
procedure TestBackup;
var
  Src, Dst: TStore;
  DbA, DbB, Json: string;
  A: TAccount;
  T: TTag;
  L: TArray<TAccount>;
  R: TBackupResult;
begin
  DbA := TPath.Combine(TPath.GetTempPath, 'vigia-bk-a.db');
  DbB := TPath.Combine(TPath.GetTempPath, 'vigia-bk-b.db');
  Json := TPath.Combine(TPath.GetTempPath, 'vigia-bk.json');
  if TFile.Exists(DbA) then TFile.Delete(DbA);
  if TFile.Exists(DbB) then TFile.Delete(DbB);
  Src := TStore.Create(DbA);
  Dst := TStore.Create(DbB);
  try
    A := NewAccount(pkGitHub);
    A.Name := 'Pessoal';
    A.Events := [ekComment, ekCiFailed];
    A.IncludeList := 'o/app';
    A.MyPrs := True;
    Src.SaveAccount(A);
    Src.AddManualKey(A.Id, 'o/app#7');
    T := Default(TTag);
    T.Name := 'Pagamentos';
    T.Keywords := 'pix';
    T.AccountId := A.Id;
    Src.SaveTag(T);
    Src.SetItemTag(T.Id, A.Id, 'o/app#7', True);
    Src.SetSetting('theme', 'dark');
    Src.SetSetting('update_last', '2026-01-01');
    ExportBackup(Src, Json, False);

    // Já existe uma conta com o mesmo nome: é atualizada, não duplicada.
    A := NewAccount(pkGitHub);
    A.Name := 'Pessoal';
    Dst.SaveAccount(A);
    R := ImportBackup(Dst, Json, False);
    L := Dst.ListAccounts;
    Check((Length(L) = 1) and (L[0].Events = [ekComment, ekCiFailed]) and L[0].MyPrs and
      (L[0].IncludeList = 'o/app'), 'backup: conta atualizada, não duplicada');
    Check(Length(Dst.ListManualKeys(L[0].Id)) = 1, 'backup: acompanhamento manual');
    Check((Length(Dst.ListTags) = 1) and Dst.ListTags[0].HasManual(L[0].Id, 'o/app#7'), 'backup: tag e marcação');
    Check((Dst.GetSetting('theme') = 'dark') and (Dst.GetSetting('update_last') = ''),
      'backup: preferência vem, estado de execução não');
    Check((R.Accounts = 1) and (R.Tags = 1), 'backup: contagem ' + R.Summary);
    R := ImportBackup(Dst, Json, False);
    Check((Length(Dst.ListAccounts) = 1) and (Length(Dst.ListTags) = 1), 'backup: importar de novo não duplica');
  finally
    Src.Free;
    Dst.Free;
  end;
  Check(UnprotectText(ProtectText('token-ç')) = 'token-ç', 'DPAPI: ida e volta');
  Check(UnprotectText('lixo') = '', 'DPAPI: texto inválido vira vazio');
end;

procedure TestI18n;
begin
  SetLanguage('en');
  Check(Tr('Configurações') = 'Settings', 'i18n: inglês');
  Check(Tr('Conta: ') = 'Account: ', 'i18n: espaço da ponta acompanha a chave');
  Check(Tr('frase sem tradução') = 'frase sem tradução', 'i18n: sem tradução fica o português');
  SetLanguage('pt');
  Check(Tr('Configurações') = 'Configurações', 'i18n: português');
end;

procedure TestVersions;
begin
  Check(CompareVersions('0.20.0', '0.21.0') < 0, 'versão: menor');
  Check(CompareVersions('v0.21.1', '0.21.0') > 0, 'versão: com v e patch maior');
  Check(CompareVersions('1.0', '1.0.0') = 0, 'versão: parte faltando vale 0');
  Check(CompareVersions('0.10.0', '0.9.9') > 0, 'versão: número, não texto');
end;

{ Formato real conferido na API pública da gitlab.com (issue e MR). Azure pela
  documentação (sem organização de teste). }
procedure TestGitLabAzure;
var
  J: TJSONObject;
  It: TItem;
  A: TAccount;
  Me: TIdentity;
begin
  J := Obj('{"iid":39956,"title":"Suporte ao Windows 11","state":"opened","due_date":"2026-10-20",' +
    '"updated_at":"2026-10-03T00:10:30.159Z","user_notes_count":2,' +
    '"assignees":[{"username":"ana","name":"Ana Lima"}],' +
    '"web_url":"https://gitlab.com/g/runner/-/work_items/39956",' +
    '"references":{"short":"#39956","full":"g/runner#39956"}}');
  try
    It := ParseGitLabItem(J, 4, False);
    Check((It.Key = 'g/runner#39956') and (It.Status = 'open') and (It.StatusCategory = 'new') and
      (It.Assignee = 'Ana Lima') and (It.CommentCount = 2) and (Trunc(It.DueDate) = EncodeDate(2026, 10, 20)),
      'GitLab: issue');
  finally
    J.Free;
  end;
  J := Obj('{"iid":7511,"title":"Corrige build","state":"opened","draft":true,' +
    '"detailed_merge_status":"requested_changes","references":{"full":"g/runner!7511"}}');
  try
    It := ParseGitLabItem(J, 4, True);
    Check((It.Key = 'g/runner!7511') and (It.Status = 'rascunho') and
      (It.ReviewState = 'CHANGES_REQUESTED'), 'GitLab: MR rascunho com mudanças pedidas');
  finally
    J.Free;
  end;
  Check((RepoOf('g/sub/app!5') = 'g/sub/app') and (RepoOf('Projeto X#9') = 'Projeto X'),
    'repo de MR do GitLab e projeto do Azure');
  A := NewAccount(pkAzure);
  A.Id := 9;
  A.BaseUrl := 'https://dev.azure.com/acme/';
  A.IncludeList := 'Loja';
  Check(ItemAllowed(A, 'Loja#12') and not ItemAllowed(A, 'Outro#3'), 'filtro: projeto do Azure');
  Me.Id := 'ana@acme.com';
  J := Obj('{"id":123,"fields":{"System.TeamProject":"Loja","System.Title":"Pix falha",' +
    '"System.State":"Active","System.AssignedTo":{"displayName":"Ana","uniqueName":"ana@acme.com"},' +
    '"System.ChangedDate":"2026-10-04T10:00:00.00Z","System.CommentCount":3,' +
    '"Microsoft.VSTS.Scheduling.DueDate":"2026-10-09T03:00:00Z","System.Tags":"Pix; Blocked"}}');
  try
    It := ParseAzureItem(J, A, Me);
    Check((It.Key = 'Loja#123') and (It.Title = 'Pix falha') and (It.StatusCategory = 'indeterminate') and
      (isAssigned in It.Sources) and (It.CommentCount = 3) and It.Flagged and
      (It.Url = 'https://dev.azure.com/acme/Loja/_workitems/edit/123'), 'Azure: work item');
  finally
    J.Free;
  end;
end;

procedure TestManualKey;
var
  G: TKeyFamily;
begin
  Check((NormalizeManualKey(' app-12 ', G) = 'APP-12') and (G = kfJira), 'chave Jira normalizada');
  Check((NormalizeManualKey('grupo/sub/app!5', G) = 'grupo/sub/app!5') and (G = kfRepo), 'chave MR do GitLab');
  Check((NormalizeManualKey('Meu Projeto#123', G) = 'Meu Projeto#123') and (G = kfAzure), 'chave Azure');
  Check((NormalizeManualKey('esasse/github-issues-tray#3', G) = 'esasse/github-issues-tray#3') and (G = kfRepo),
    'chave GitHub');
  Check(NormalizeManualKey('qualquer coisa', G) = '', 'chave inválida');
  Check(NormalizeManualKey('o/r#', G) = '', 'GitHub sem número');
end;

procedure TestDiff;
var
  A: TAccount;
  Me: TIdentity;
  Old, New: TItems;
  Ev: TEvents;
  Today: TDateTime;
begin
  A := NewAccount(pkJiraServer);
  A.Id := 1;
  A.Name := 'Acme';
  A.DueDays := 2;
  Me.Id := 'eu';
  Today := EncodeDate(2026, 10, 1);

  // Linha de base: nada além de prazo.
  New := [MkItem('P-1', 'Aberto', 1, 'x', [isAssigned]),
          MkItem('P-2', 'Aberto', 0, '', [isWatching], Today + 1),
          MkItem('P-3', 'Aberto', 0, '', [isWatching], Today - 3)];
  Ev := DiffItems(nil, New, A, Me, Today, True);
  Check(Kinds(Ev) = 'P-2:Prazo chegando;P-3:Prazo vencido;', 'baseline só avisa prazo: ' + Kinds(Ev));
  Check((New[1].DueAlert = 1) and (New[2].DueAlert = 2), 'baseline grava nível de prazo');

  // Mesma busca de novo: silêncio (prazo já avisado não repete).
  Old := New;
  New := [MkItem('P-1', 'Aberto', 1, 'x', [isAssigned]),
          MkItem('P-2', 'Aberto', 0, '', [isWatching], Today + 1),
          MkItem('P-3', 'Aberto', 0, '', [isWatching], Today - 3)];
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Length(Ev) = 0, 'sem mudança, sem evento: ' + Kinds(Ev));

  // Status, comentário de outro, comentário meu, nova associação, menção.
  Old := New;
  New := [MkItem('P-1', 'Em teste', 2, 'maria', [isAssigned]),
          MkItem('P-2', 'Aberto', 1, 'eu', [isWatching], Today + 1),
          MkItem('P-3', 'Aberto', 1, 'joao', [isWatching], Today - 3),
          MkItem('P-4', 'Aberto', 0, '', [isAssigned])];
  New[2].MentionsMe := True;
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Kinds(Ev) = 'P-1:Mudança de status;P-1:Novo comentário;P-3:Menção;P-4:Fui associado;',
    'eventos de mudança: ' + Kinds(Ev));

  // Prazo mudou: avisa de novo.
  Old := New;
  New := Copy(Old);
  New[1].DueDate := Today;
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Kinds(Ev) = 'P-2:Prazo chegando;', 'prazo novo reavisa: ' + Kinds(Ev));

  // Sinalização nova vira evento (snapshot no formato novo, com categoria).
  Old := New;
  Old[0].StatusCategory := 'new';
  New := Copy(Old);
  New[0].Flagged := True;
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Kinds(Ev) = 'P-1:Sinalizada;', 'sinalizada vira evento: ' + Kinds(Ev));

  // Filtro por regra da conta.
  Check(Length(FilterEvents(Ev, [ekComment])) = 0, 'filtro remove tipo desligado');

  // GitHub: comentário só conta com notification nova.
  A.Kind := pkGitHub;
  Old := [MkItem('o/r#1', 'open', 1, '', [isAssigned])];
  New := [MkItem('o/r#1', 'open', 2, '', [isAssigned])];
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Length(Ev) = 0, 'GitHub: comentário sem notification (meu) não avisa');
  New[0].UnreadReason := 'comment';
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Kinds(Ev) = 'o/r#1:Novo comentário;', 'GitHub: comentário com notification avisa');
  New := [MkItem('o/r#2', 'open', 0, '', [isReview])];
  Ev := DiffItems(Old, New, A, Me, Today, False);
  Check(Kinds(Ev) = 'o/r#2:Review de PR pedido;', 'GitHub: review pedido');
end;

{ --lottie <arquivo.json> <saida.png>: folha com 8 quadros do Lottie, para
  conferir as poses do mascote com o mesmo motor do app (Skottie). }
procedure SaveLottieSheet(const AFile, AOut: string);
const
  Cell = 160;
  Count = 8;
var
  Anim: ISkottieAnimation;
  Surface: ISkSurface;
  I: Integer;
  R: TRectF;
begin
  Anim := TSkottieAnimation.MakeFromFile(AFile);
  if Anim = nil then
    raise Exception.Create('Lottie inválido: ' + AFile);
  Surface := TSkSurface.MakeRaster(Cell * Count, Cell);
  Surface.Canvas.Clear($FF1E2228);
  for I := 0 to Count - 1 do
  begin
    Anim.SeekFrame(Anim.OutPoint * I / Count);
    R := TRectF.Create(I * Cell, 0, (I + 1) * Cell, Cell);
    Anim.Render(Surface.Canvas, R);
  end;
  Surface.MakeImageSnapshot.EncodeToFile(AOut);
  Writeln('ok ', AOut);
end;

{ --icons <pasta>: salva o ícone da tray em 4 estados, ampliado, para olhar. }
procedure SaveIcons(const ADir: string);
const
  Cases: array[0..3] of Integer = (0, 3, 12, 0);
var
  I: Integer;
  Ico: TIcon;
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  Ico := TIcon.Create;
  try
    Bmp.SetSize(4 * 72, 72);
    Bmp.Canvas.Brush.Color := RGB(240, 240, 240);
    Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
    for I := 0 to 3 do
    begin
      Ico.Handle := MakeTrayIcon(Cases[I], I = 3);
      DrawIconEx(Bmp.Canvas.Handle, I * 72 + 4, 4, Ico.Handle, 64, 64, 0, 0, DI_NORMAL);
    end;
    Bmp.SaveToFile(IncludeTrailingPathDelimiter(ADir) + 'vigia-icons.bmp');
  finally
    Ico.Free;
    Bmp.Free;
  end;
end;

{ --live: roda a busca de verdade nas contas ligadas do banco real. }
procedure RunLive;
var
  A: TAccount;
  Items: TItems;
  It: TItem;
  I: Integer;
  Me: TIdentity;
begin
  for A in Store.ListAccounts do
  begin
    if not A.Enabled then
      Continue;
    Write(A.Name, ' (', ProviderNames[A.Kind], '): ');
    try
      Writeln('eu = ', TestConnection(A, LoadSecret(A.SecretTarget)));
      Items := FetchItems(A, LoadSecret(A.SecretTarget), Store.ListManualKeys(A.Id), Me);
      Writeln('  ', Length(Items), ' itens');
      if (A.Kind <> pkGitHub) and (Items <> nil) then
      begin
        Writeln('  CheckItem ', Items[0].Key, ' = ', CheckItem(A, LoadSecret(A.SecretTarget), Items[0].Key));
        // Só leitura: lista as transições, não aplica nenhuma.
        for var T in FetchTransitions(A, LoadSecret(A.SecretTarget), Items[0].Key) do
          Writeln('  transição ', T.Id, ': ', T.Name, ' -> ', T.ToStatus);
        try
          CheckItem(A, LoadSecret(A.SecretTarget), 'NAOEXISTE-999999');
          Writeln('  CheckItem inexistente NÃO falhou (errado)');
        except
          on E: Exception do
            Writeln('  CheckItem inexistente falhou como esperado: ', E.Message);
        end;
      end;
      for I := 0 to High(Items) do
        if I < 8 then
        begin
          It := Items[I];
          Writeln(Format('  %-16s %-3s %-22s prazo=%s coment=%d ultimo=%s mencao=%s',
            [It.Key, IfThen(isAssigned in It.Sources, 'eu', 'obs'), Copy(It.Status, 1, 22),
             IfThen(It.DueDate = 0, '-', DateToStr(It.DueDate)), It.CommentCount,
             It.LastCommentBy, BoolToStr(It.MentionsMe, True)]));
        end;
    except
      on E: Exception do
        Writeln('ERRO ', E.Message);
    end;
  end;
end;

begin
  if ParamStr(1) = '--lottie' then
  begin
    SaveLottieSheet(ParamStr(2), ParamStr(3));
    Exit;
  end;
  if ParamStr(1) = '--icons' then
  begin
    SaveIcons(ParamStr(2));
    Exit;
  end;
  if ParamStr(1) = '--live' then
  begin
    RunLive;
    Exit;
  end;
  try
    TestDates;
    TestGitHub;
    TestJiraServer;
    TestJiraCloud;
    TestJiraFlagAndDueField;
    TestDiff;
    TestManualKey;
    TestGitLabAzure;
    TestVersions;
    TestI18n;
    TestBackup;
    TestCleanComment;
    TestTags;
    TestPrsAndFilter;
    TestSecrets;
    TestStore;
    Writeln('TUDO OK');
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      ExitCode := 1;
    end;
  end;
end.
