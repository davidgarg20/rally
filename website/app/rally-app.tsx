"use client";

import { FormEvent, KeyboardEvent as ReactKeyboardEvent, useCallback, useEffect, useState } from "react";
import { type Venue, venueFixtures } from "./venues";

type Player = {
  id: string;
  username: string;
  display_name: string;
  phone_e164: string;
  home_city: string;
  rating: number;
  rd: number;
  matches_played: number;
};

type Participant = {
  player_id: string | null;
  username: string | null;
  display_name: string | null;
  team: number;
  is_submitter: boolean;
  confirmed: boolean;
  disputed: boolean;
};

type RallyMatch = {
  id: string;
  status: string;
  played_at: string;
  venue: string | null;
  participants: Participant[];
  games: Array<{ team1_points: number; team2_points: number }>;
};

type PlayerSearchEntry = {
  id: string;
  username: string;
  display_name: string;
};

type LeaderboardEntry = {
  rank: number;
  player_id: string;
  username: string;
  display_name: string;
  rating: number;
  matches_played: number;
};

type LeaderboardResponse = {
  entries: LeaderboardEntry[];
};

type ChallengePlayer = {
  id: string;
  username: string;
  display_name: string;
  rating: number;
};

type RallyChallenge = {
  id: string;
  status: "pending" | "accepted" | "declined" | "cancelled";
  created_at: string;
  responded_at: string | null;
  challenger: ChallengePlayer;
  challenged: ChallengePlayer;
};

type RallyAppProps = {
  open: boolean;
  onClose: () => void;
  preferredVenueId?: string | null;
};

const apiUrl = (import.meta.env.VITE_RALLY_API_URL || "http://localhost:8000").replace(/\/$/, "");
const tokenKey = "rally_access_token";

async function api<T>(path: string, init: RequestInit = {}, token?: string): Promise<T> {
  const response = await fetch(`${apiUrl}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.message || "Something went wrong. Please try again.");
  return body as T;
}

export default function RallyApp({ open, onClose, preferredVenueId = null }: RallyAppProps) {
  const [token, setToken] = useState(() =>
    typeof window === "undefined" ? "" : window.localStorage.getItem(tokenKey) || "",
  );
  const [player, setPlayer] = useState<Player | null>(null);
  const [matches, setMatches] = useState<RallyMatch[]>([]);
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [challenges, setChallenges] = useState<RallyChallenge[]>([]);
  const [needsProfile, setNeedsProfile] = useState(false);
  const [authMode, setAuthMode] = useState<"signup" | "login">("signup");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [showMatchForm, setShowMatchForm] = useState(false);
  const [venues, setVenues] = useState<Venue[]>(venueFixtures);
  const [selectedVenueId, setSelectedVenueId] = useState(preferredVenueId || "");
  const [opponentQuery, setOpponentQuery] = useState("");
  const [opponentResults, setOpponentResults] = useState<PlayerSearchEntry[]>([]);
  const [opponentSearchOpen, setOpponentSearchOpen] = useState(false);
  const [opponentSearchBusy, setOpponentSearchBusy] = useState(false);
  const [opponentSearchError, setOpponentSearchError] = useState(false);
  const [activeOpponentIndex, setActiveOpponentIndex] = useState(-1);

  const loadAccount = useCallback(async (activeToken: string) => {
    try {
      const me = await api<Player>("/players/me", {}, activeToken);
      setPlayer(me);
      setNeedsProfile(false);
      const [recent, standings, playerChallenges] = await Promise.all([
        api<RallyMatch[]>("/players/me/matches", {}, activeToken),
        api<LeaderboardResponse>("/leaderboard?limit=100", {}, activeToken)
          .catch(() => ({ entries: [] })),
        api<RallyChallenge[]>("/challenges", {}, activeToken).catch(() => []),
      ]);
      setMatches(recent);
      setLeaderboard(standings.entries);
      setChallenges(playerChallenges);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load your account.";
      if (message.toLowerCase().includes("player not found")) {
        setNeedsProfile(true);
        setPlayer(null);
      } else {
        setError(message);
      }
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    if (open && token) {
      void Promise.resolve().then(() => {
        if (!cancelled) return loadAccount(token);
      });
    }
    return () => { cancelled = true; };
  }, [loadAccount, open, token]);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [onClose, open]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    void api<Venue[]>(`/venues?city=${encodeURIComponent(player?.home_city || "BLR")}`)
      .then((availableVenues) => {
        if (!cancelled && availableVenues.length > 0) setVenues(availableVenues);
      })
      .catch(() => undefined);
    return () => { cancelled = true; };
  }, [open, player?.home_city]);

  useEffect(() => {
    if (!open || !preferredVenueId) return;
    let cancelled = false;
    void Promise.resolve().then(() => {
      if (cancelled) return;
      setSelectedVenueId(preferredVenueId);
      if (player) setShowMatchForm(true);
    });
    return () => { cancelled = true; };
  }, [open, player, preferredVenueId]);

  useEffect(() => {
    const query = opponentQuery.trim().replace(/^@/, "");
    if (!open || !showMatchForm || !token || !opponentSearchOpen || !query) return;

    let cancelled = false;
    const timer = window.setTimeout(() => {
      void api<PlayerSearchEntry[]>(`/players/search?q=${encodeURIComponent(query)}`, {}, token)
        .then((results) => {
          if (!cancelled) {
            setOpponentResults(results);
            setOpponentSearchError(false);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setOpponentResults([]);
            setOpponentSearchError(true);
          }
        })
        .finally(() => {
          if (!cancelled) setOpponentSearchBusy(false);
        });
    }, 250);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [open, opponentQuery, opponentSearchOpen, showMatchForm, token]);

  const selectedVenue = venues.find((venue) => venue.id === selectedVenueId) || null;
  const myStanding = player ? leaderboard.find((entry) => entry.player_id === player.id) : null;
  const leaderboardRows = [
    ...leaderboard.slice(0, 5),
    ...(myStanding && myStanding.rank > 5 ? [myStanding] : []),
  ];

  if (!open) return null;

  async function submitAuth(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const form = new FormData(event.currentTarget);
    try {
      const result = await api<{ access_token: string }>(`/auth/${authMode === "signup" ? "register" : "login"}`, {
        method: "POST",
        body: JSON.stringify({ email: form.get("email"), password: form.get("password") }),
      });
      window.localStorage.setItem(tokenKey, result.access_token);
      setToken(result.access_token);
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Unable to continue.");
    } finally {
      setBusy(false);
    }
  }

  async function createProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const form = new FormData(event.currentTarget);
    try {
      const created = await api<Player>("/players", {
        method: "POST",
        body: JSON.stringify({
          username: String(form.get("username") || "").toLowerCase(),
          display_name: form.get("display_name"),
          phone_e164: form.get("phone_e164"),
          home_city: form.get("home_city") || "BLR",
        }),
      }, token);
      setPlayer(created);
      setNeedsProfile(false);
      setMatches([]);
    } catch (profileError) {
      setError(profileError instanceof Error ? profileError.message : "Unable to create your profile.");
    } finally {
      setBusy(false);
    }
  }

  async function submitMatch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!player) return;
    setBusy(true);
    setError("");
    const form = new FormData(event.currentTarget);
    try {
      const created = await api<RallyMatch>("/matches", {
        method: "POST",
        body: JSON.stringify({
          format: "S",
          played_at: new Date().toISOString(),
          venue: venues.find((venue) => venue.id === form.get("venue_id"))?.name || null,
          team1_phones: [player.username],
          team2_phones: [String(form.get("opponent") || "").replace(/^@/, "")],
          games: [{
            game_no: 1,
            team1_points: Number(form.get("my_score")),
            team2_points: Number(form.get("opponent_score")),
          }],
        }),
      }, token);
      setMatches((current) => [created, ...current]);
      setShowMatchForm(false);
      setOpponentQuery("");
      setOpponentResults([]);
      setOpponentSearchOpen(false);
    } catch (matchError) {
      setError(matchError instanceof Error ? matchError.message : "Unable to submit this match.");
    } finally {
      setBusy(false);
    }
  }

  async function confirmMatch(matchId: string) {
    setBusy(true);
    setError("");
    try {
      await api(`/matches/${matchId}/confirm`, { method: "POST" }, token);
      await loadAccount(token);
    } catch (confirmError) {
      setError(confirmError instanceof Error ? confirmError.message : "Unable to confirm this match.");
    } finally {
      setBusy(false);
    }
  }

  async function disputeMatch(matchId: string) {
    if (!window.confirm("Invalidate this pending result? No player ratings will change.")) return;
    setBusy(true);
    setError("");
    try {
      const updated = await api<RallyMatch>(`/matches/${matchId}/dispute`, { method: "POST" }, token);
      setMatches((current) => current.map((match) => match.id === matchId ? updated : match));
    } catch (disputeError) {
      setError(disputeError instanceof Error ? disputeError.message : "Unable to reject this result.");
    } finally {
      setBusy(false);
    }
  }

  async function createChallenge(opponentUsername: string) {
    setBusy(true);
    setError("");
    try {
      const created = await api<RallyChallenge>("/challenges", {
        method: "POST",
        body: JSON.stringify({ opponent_username: opponentUsername }),
      }, token);
      setChallenges((current) => [created, ...current]);
    } catch (challengeError) {
      setError(challengeError instanceof Error ? challengeError.message : "Unable to send this challenge.");
    } finally {
      setBusy(false);
    }
  }

  async function updateChallenge(
    challengeId: string,
    action: "accept" | "decline" | "cancel",
  ) {
    setBusy(true);
    setError("");
    try {
      const updated = await api<RallyChallenge>(`/challenges/${challengeId}/${action}`, {
        method: "POST",
      }, token);
      setChallenges((current) => current.map((challenge) => (
        challenge.id === challengeId ? updated : challenge
      )));
    } catch (challengeError) {
      setError(challengeError instanceof Error ? challengeError.message : "Unable to update this challenge.");
    } finally {
      setBusy(false);
    }
  }

  function signOut() {
    window.localStorage.removeItem(tokenKey);
    setToken("");
    setPlayer(null);
    setMatches([]);
    setLeaderboard([]);
    setChallenges([]);
    setNeedsProfile(false);
    setError("");
  }

  function updateOpponentQuery(value: string) {
    setOpponentQuery(value);
    setOpponentSearchOpen(true);
    setOpponentSearchError(false);
    setActiveOpponentIndex(-1);
    if (value.trim().replace(/^@/, "")) {
      setOpponentSearchBusy(true);
    } else {
      setOpponentSearchBusy(false);
      setOpponentResults([]);
    }
  }

  function selectOpponent(opponent: PlayerSearchEntry) {
    setOpponentQuery(`@${opponent.username}`);
    setOpponentResults([]);
    setOpponentSearchOpen(false);
    setOpponentSearchBusy(false);
    setOpponentSearchError(false);
    setActiveOpponentIndex(-1);
  }

  function handleOpponentKeyDown(event: ReactKeyboardEvent<HTMLInputElement>) {
    if (event.key === "Escape" && opponentSearchOpen) {
      event.preventDefault();
      event.stopPropagation();
      setOpponentSearchOpen(false);
      return;
    }
    if (!opponentSearchOpen || opponentResults.length === 0) return;
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setActiveOpponentIndex((current) => (current + 1) % opponentResults.length);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setActiveOpponentIndex((current) => current <= 0 ? opponentResults.length - 1 : current - 1);
    } else if (event.key === "Enter" && activeOpponentIndex >= 0) {
      event.preventDefault();
      selectOpponent(opponentResults[activeOpponentIndex]);
    }
  }

  return (
    <section className="rally-app" aria-label="Rally player app" role="dialog" aria-modal="true">
      <header className="app-shell-header">
        <button className="app-brand" type="button" onClick={onClose}><span>↗</span> RALLY</button>
        <div className="app-shell-actions">
          {token && <button type="button" onClick={signOut}>Sign out</button>}
          <button className="app-close" type="button" onClick={onClose} aria-label="Close Rally app">×</button>
        </div>
      </header>

      {!token && (
        <div className="auth-layout">
          <div className="auth-story">
            <span className="section-kicker lime">Rally player account</span>
            <h2>One number.<br /><em>Every match.</em></h2>
            <p>Create your profile, record scores and let validated results shape your Glicko‑2 rating.</p>
            <div className="auth-rating"><small>EVERY PLAYER STARTS AT</small><strong>1500</strong><span>High uncertainty · Fast calibration</span></div>
          </div>
          <form className="app-form auth-form" onSubmit={submitAuth}>
            <div className="auth-tabs">
              <button type="button" className={authMode === "signup" ? "active" : ""} onClick={() => setAuthMode("signup")}>Create account</button>
              <button type="button" className={authMode === "login" ? "active" : ""} onClick={() => setAuthMode("login")}>Sign in</button>
            </div>
            <h3>{authMode === "signup" ? "Join Rally" : "Welcome back"}</h3>
            <label>Email<input name="email" type="email" autoComplete="email" required placeholder="you@example.com" /></label>
            <label>Password<input name="password" type="password" autoComplete={authMode === "signup" ? "new-password" : "current-password"} minLength={8} required placeholder="At least 8 characters" /></label>
            {error && <p className="app-error" role="alert">{error}</p>}
            <button className="app-primary" type="submit" disabled={busy}>{busy ? "Working…" : authMode === "signup" ? "Create free account →" : "Sign in →"}</button>
            <small>Free during Rally&apos;s early-access period.</small>
          </form>
        </div>
      )}

      {token && needsProfile && (
        <div className="profile-setup">
          <div><span className="section-kicker">Step 2 of 2</span><h2>Build your<br /><em>player card.</em></h2><p>Your phone number helps existing opponents find you. It is never shown on your public profile.</p></div>
          <form className="app-form" onSubmit={createProfile}>
            <label>Display name<input name="display_name" required maxLength={80} placeholder="Arjun Patel" /></label>
            <label>Username<input name="username" required minLength={3} maxLength={20} pattern="[a-z][a-z0-9_]{2,19}" placeholder="arjunp" /></label>
            <label>Phone number<input name="phone_e164" type="tel" required pattern="\+[1-9][0-9]{7,14}" placeholder="+919876543210" /></label>
            <label>Home city<input name="home_city" required defaultValue="BLR" placeholder="BLR" /></label>
            {error && <p className="app-error" role="alert">{error}</p>}
            <button className="app-primary" type="submit" disabled={busy}>{busy ? "Creating…" : "Create player profile →"}</button>
          </form>
        </div>
      )}

      {token && player && (
        <div className="player-dashboard">
          <div className="dashboard-welcome"><div><span className="section-kicker">Player dashboard</span><h2>Good game,<br /><em>{player.display_name.split(" ")[0]}.</em></h2><p>@{player.username} · {player.home_city}</p></div><button className="app-primary log-match-button" type="button" onClick={() => setShowMatchForm(true)}>＋ Log a match</button></div>
          {error && <p className="app-error dashboard-error" role="alert">{error}</p>}
          <div className="rating-dashboard-grid">
            <article className="dashboard-rating-card"><small>YOUR RALLY RATING</small><strong>{Math.round(player.rating)}</strong><div><span>Glicko‑2</span><span>{player.matches_played === 0 ? "Calibrating" : "Active"} ●</span></div></article>
            <article><small>VALIDATED MATCHES</small><strong>{player.matches_played}</strong><p>{player.matches_played < 5 ? `${5 - player.matches_played} more to enter leaderboards.` : "Leaderboard eligible."}</p></article>
          </div>

          <section className="app-leaderboard" aria-labelledby="app-leaderboard-title">
            <div className="app-leaderboard-head">
              <div><small>RALLY RANKINGS</small><h3 id="app-leaderboard-title">Leaderboard</h3></div>
              <p>Players enter after five validated matches. Ratings update only after both sides confirm a result.</p>
            </div>
            <div className="app-leaderboard-labels" aria-hidden="true"><span>Rank / player</span><span>Matches</span><span>Rating</span><span>Action</span></div>
            {leaderboardRows.length === 0 ? (
              <div className="app-leaderboard-empty"><b>The leaderboard is calibrating.</b><span>{player.matches_played < 5 ? `Complete ${5 - player.matches_played} more validated match${5 - player.matches_played === 1 ? "" : "es"} to qualify.` : "Eligible players will appear here as ratings settle."}</span></div>
            ) : leaderboardRows.map((entry, index) => {
              const pendingChallenge = challenges.find((challenge) => (
                challenge.status === "pending"
                && (challenge.challenger.id === entry.player_id || challenge.challenged.id === entry.player_id)
              ));
              return (
                <article className={entry.player_id === player.id ? "is-you" : ""} key={entry.player_id}>
                  {index === 5 && <span className="leaderboard-gap" aria-hidden="true">•••</span>}
                  <strong>#{entry.rank}</strong>
                  <span className="leaderboard-player-avatar" aria-hidden="true">{entry.display_name.slice(0, 1).toUpperCase()}</span>
                  <div><b>{entry.display_name}{entry.player_id === player.id ? " · You" : ""}</b><small>@{entry.username}</small></div>
                  <span className="leaderboard-match-count">{entry.matches_played}</span>
                  <b className="leaderboard-rating">{Math.round(entry.rating)}</b>
                  {entry.player_id === player.id ? (
                    <span className="leaderboard-self">Your row</span>
                  ) : (
                    <button
                      className="leaderboard-challenge-button"
                      type="button"
                      disabled={busy || Boolean(pendingChallenge)}
                      onClick={() => void createChallenge(entry.username)}
                    >
                      {pendingChallenge ? "Pending" : "Challenge →"}
                    </button>
                  )}
                </article>
              );
            })}
          </section>

          <section className="app-challenges" aria-labelledby="app-challenges-title">
            <div className="app-challenges-head">
              <div><small>GAME CHALLENGES</small><h3 id="app-challenges-title">Set up your next game.</h3></div>
              <p>Challenge a player from the leaderboard, then accept or decline invitations here.</p>
              <span>{challenges.filter((challenge) => challenge.status === "pending").length} pending</span>
            </div>
            {challenges.length === 0 ? (
              <div className="challenge-empty">
                <span aria-hidden="true">↗</span>
                <div><b>No challenges yet.</b><p>Choose any opponent from the leaderboard above to invite them to a game.</p></div>
              </div>
            ) : (
              <div className="challenge-grid">
                {challenges.slice(0, 8).map((challenge) => {
                  const incoming = challenge.challenged.id === player.id;
                  const opponent = incoming ? challenge.challenger : challenge.challenged;
                  return (
                    <article className={`challenge-card ${challenge.status}`} key={challenge.id}>
                      <div className="challenge-card-head">
                        <small>{incoming ? "INCOMING CHALLENGE" : "CHALLENGE SENT"}</small>
                        <span>{challenge.status}</span>
                      </div>
                      <div className="challenge-player">
                        <span aria-hidden="true">{opponent.display_name.slice(0, 1).toUpperCase()}</span>
                        <div><b>{opponent.display_name}</b><small>@{opponent.username} · {Math.round(opponent.rating)} rating</small></div>
                      </div>
                      <p>{challenge.status === "accepted" ? "Game on — coordinate a court and time with your opponent." : `Sent ${new Date(challenge.created_at).toLocaleDateString()}`}</p>
                      {challenge.status === "pending" && incoming && (
                        <div className="challenge-actions">
                          <button type="button" disabled={busy} onClick={() => void updateChallenge(challenge.id, "accept")}>Accept game</button>
                          <button className="challenge-secondary" type="button" disabled={busy} onClick={() => void updateChallenge(challenge.id, "decline")}>Decline</button>
                        </div>
                      )}
                      {challenge.status === "pending" && !incoming && (
                        <div className="challenge-actions single">
                          <button className="challenge-secondary" type="button" disabled={busy} onClick={() => void updateChallenge(challenge.id, "cancel")}>Cancel challenge</button>
                        </div>
                      )}
                    </article>
                  );
                })}
              </div>
            )}
          </section>

          {showMatchForm && (
            <form className="app-form match-form" onSubmit={submitMatch}>
              <div className="match-form-head"><div><small>NEW SINGLES RESULT</small><h3>Log the score</h3></div><button type="button" onClick={() => setShowMatchForm(false)}>×</button></div>
              <div
                className="opponent-picker"
                onBlur={(event) => {
                  if (!event.currentTarget.contains(event.relatedTarget)) setOpponentSearchOpen(false);
                }}
              >
                <label htmlFor="opponent-username">Opponent username</label>
                <input
                  id="opponent-username"
                  name="opponent"
                  required
                  autoComplete="off"
                  placeholder="Search username or player name"
                  value={opponentQuery}
                  role="combobox"
                  aria-autocomplete="list"
                  aria-expanded={opponentSearchOpen}
                  aria-controls="opponent-results"
                  aria-activedescendant={activeOpponentIndex >= 0 ? `opponent-option-${opponentResults[activeOpponentIndex]?.id}` : undefined}
                  onChange={(event) => updateOpponentQuery(event.target.value)}
                  onFocus={() => setOpponentSearchOpen(true)}
                  onKeyDown={handleOpponentKeyDown}
                />
                {opponentSearchOpen && (
                  <div className="opponent-results" id="opponent-results" role="listbox" aria-label="Matching Rally players">
                    {!opponentQuery.trim() && <p>Start typing to find a registered player.</p>}
                    {opponentQuery.trim() && opponentSearchBusy && <p role="status">Finding players…</p>}
                    {opponentQuery.trim() && !opponentSearchBusy && opponentSearchError && <p>Player search is unavailable. Try again.</p>}
                    {opponentQuery.trim() && !opponentSearchBusy && !opponentSearchError && opponentResults.length === 0 && <p>No matching players found.</p>}
                    {!opponentSearchBusy && opponentResults.map((opponent, index) => (
                      <button
                        type="button"
                        id={`opponent-option-${opponent.id}`}
                        role="option"
                        aria-selected={activeOpponentIndex === index}
                        className={activeOpponentIndex === index ? "active" : ""}
                        key={opponent.id}
                        onMouseEnter={() => setActiveOpponentIndex(index)}
                        onClick={() => selectOpponent(opponent)}
                      >
                        <span className="opponent-avatar" aria-hidden="true">{opponent.display_name.slice(0, 1).toUpperCase()}</span>
                        <span><b>{opponent.display_name}</b><small>@{opponent.username}</small></span>
                        <i>Choose</i>
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <div className="score-inputs"><label>Your score<input name="my_score" type="number" min="0" max="30" required placeholder="21" /></label><b>:</b><label>Opponent<input name="opponent_score" type="number" min="0" max="30" required placeholder="17" /></label></div>
              <label>Venue <span>optional</span><select name="venue_id" value={selectedVenue?.id || ""} onChange={(event) => setSelectedVenueId(event.target.value)}><option value="">Venue not listed</option>{venues.map((venue) => <option value={venue.id} key={venue.id}>{venue.name} · {venue.area}</option>)}</select></label>
              <p>The opponent will confirm this result before either rating changes.</p>
              <button className="app-primary" type="submit" disabled={busy}>{busy ? "Submitting…" : "Submit for confirmation →"}</button>
            </form>
          )}

          <div className="match-history">
            <div className="match-history-head"><div><small>MATCH CENTRE</small><h3>Recent results</h3></div><span>{matches.length} total</span></div>
            {matches.length === 0 ? <div className="app-empty"><b>No matches yet.</b><p>Log your first score to start calibrating your rating.</p></div> : matches.map((match) => {
              const opponent = match.participants.find((participant) => participant.player_id !== player.id);
              const currentParticipant = match.participants.find((participant) => participant.player_id === player.id);
              const game = match.games[0];
              return <article className="app-match-row" key={match.id}>
                <span className={`match-status ${match.status}`}>{match.status}</span>
                <div><b>vs. {opponent?.display_name || opponent?.username || "Invited player"}</b><small>{match.venue || "Venue not added"} · {new Date(match.played_at).toLocaleDateString()}</small></div>
                <strong>{game ? `${game.team1_points}–${game.team2_points}` : "—"}</strong>
                {match.status === "pending" && currentParticipant && (
                  <div className="match-actions">
                    {!currentParticipant.is_submitter && <button type="button" disabled={busy} onClick={() => void confirmMatch(match.id)}>Confirm</button>}
                    <button className="match-reject" type="button" disabled={busy} onClick={() => void disputeMatch(match.id)}>{currentParticipant.is_submitter ? "Cancel result" : "Reject result"}</button>
                  </div>
                )}
              </article>;
            })}
          </div>
        </div>
      )}
    </section>
  );
}
