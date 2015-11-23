unit GamesList;

interface

uses
  Generics.Collections, Game, GamePlayer;

type

  TGamesList = class
    private
      var m_games: TList<TGame>;
      var m_maxGames: UInt32;

      var m_onCreateGame: TGameGenericEvent;
      var m_onDestroyGame: TGameGenericEvent;

      procedure DestroyGames;
    public
      constructor Create;
      destructor Destroy; override;
      function GetGameById(gameId: Byte): TGame;
      function getPlayerGame(player: TGamePlayer): TGame;
      function CreateGame(name, password: AnsiString; gameInfo: TPlayerCreateGameInfo; artifact: UInt32; onUpdate: TGameEvent): TGame;
      procedure DestroyGame(game: Tgame);

      property OnCreateGame: TGameGenericEvent read m_onCreateGame;
      property OnDestroyGame: TGameGenericEvent read m_onDestroyGame;
  end;

implementation

uses GameServerExceptions;

constructor TGamesList.Create;
begin
  inherited;
  m_maxGames := 10;
  m_games := TList<TGame>.Create;
  m_onCreateGame := TGameGenericEvent.Create;
  m_onDestroyGame := TGameGenericEvent.Create;
end;

destructor TGamesList.Destroy;
begin
  inherited;
  DestroyGames;
  m_games.Free;
  m_onCreateGame.Destroy;
  m_onDestroyGame.Destroy;
end;

procedure TGamesList.DestroyGames;
var
  game: TGame;
begin
  for game in m_games do
  begin
    game.Free;
  end;
end;

function TGamesList.CreateGame(name, password: AnsiString; gameInfo: TPlayerCreateGameInfo; artifact: UInt32; onUpdate: TGameEvent): TGame;
var
  game: TGame;
begin

  if m_games.Count >= m_maxGames then
  begin
    raise LobbyGamesFullException.CreateFmt('oups, too much game', []);
  end;
  game := TGame.Create(name, password, gameInfo, artifact, onUpdate);
  game.Id := m_games.Add(game);
  m_onCreateGame.Trigger(game);
  Result := game;
end;

procedure TGamesList.DestroyGame(game: TGame);
var
  res: Integer;
begin
  res := m_games.Remove(game);
  if not (res = -1) then
  begin
    m_onDestroyGame.Trigger(game);
    game.Free;
  end;
end;

function TGamesList.GetGameById(gameId: Byte): TGame;
var
  game: TGame;
begin
  for game in m_games do
  begin
    if game.Id = gameId then
    begin
      Exit(game);
    end;
  end;
  raise GameNotFoundException.Create('Game not found');
  Exit(nil);
end;

function TGamesList.getPlayerGame(player: TGamePlayer): TGame;
begin
  Exit(self.GetGameById(player.Data.playerInfo1.game));
end;

end.