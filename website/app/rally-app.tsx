"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
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
};

type RallyMatch = {
  id: string;
  status: string;
  played_at: string;
  venue: string | null;
  participants: Participant[];
  games: Array<{ team1_points: number; team2_points: number }>;
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
  const [needsProfile, setNeedsProfile] = useState(false);
  const [authMode, setAuthMode] = useState<"signup" | "login">("signup");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [showMatchForm, setShowMatchForm] = useState(false);
  const [venues, setVenues] = useState<Venue[]>(venueFixtures);
  const [selectedVenueId, setSelectedVenueId] = useState(preferredVenueId || "");

  const loadAccount = useCallback(async (activeToken: string) => {
    try {
      const me = await api<Player>("/players/me", {}, activeToken);
      setPlayer(me);
      setNeedsProfile(false);
      const recent = await api<RallyMatch[]>("/players/me/matches", {}, activeToken);
      setMatches(recent);
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

  const selectedVenue = venues.find((venue) => venue.id === selectedVenueId) || null;

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
      event.currentTarget.reset();
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

  function signOut() {
    window.localStorage.removeItem(tokenKey);
    setToken("");
    setPlayer(null);
    setMatches([]);
    setNeedsProfile(false);
    setError("");
  }

  function chooseVenue(venueId: string) {
    setSelectedVenueId(venueId);
    setShowMatchForm(true);
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
            <article><small>RATING DEVIATION</small><strong>±{Math.round(player.rd)}</strong><p>Gets smaller as your rating becomes more reliable.</p></article>
            <article><small>VALIDATED MATCHES</small><strong>{player.matches_played}</strong><p>{player.matches_played < 5 ? `${5 - player.matches_played} more to enter leaderboards.` : "Leaderboard eligible."}</p></article>
          </div>

          <section className="app-venues" aria-labelledby="app-venues-title">
            <div className="app-venues-head">
              <div><small>COURTS NEAR {player.home_city}</small><h3 id="app-venues-title">Pick where you played.</h3></div>
              <p>Compare distance, price and rated nights. Selecting a court adds it directly to your match.</p>
            </div>
            <div className="app-venue-grid">
              {venues.map((venue) => (
                <article className={selectedVenueId === venue.id ? "selected" : ""} key={venue.id}>
                  <div className="app-venue-title"><div><h4>{venue.name}</h4><span>{venue.area} · {venue.distance_km} km</span></div>{venue.rated_night && <b>RATED · {venue.rated_night.toUpperCase()}</b>}</div>
                  <div className="app-venue-meta"><span>{venue.courts} courts</span><span>₹{venue.hourly_rate}/hr</span><span>{venue.players_at_level} at your level</span></div>
                  <div className="app-venue-slots" aria-label={`Upcoming slots at ${venue.name}`}>{venue.slots.slice(0, 2).map((slot) => <span key={slot}>{slot}</span>)}</div>
                  <button type="button" onClick={() => chooseVenue(venue.id)}>{selectedVenueId === venue.id ? "Selected ✓" : "Use this venue →"}</button>
                </article>
              ))}
            </div>
          </section>

          {showMatchForm && (
            <form className="app-form match-form" onSubmit={submitMatch}>
              <div className="match-form-head"><div><small>NEW SINGLES RESULT</small><h3>Log the score</h3></div><button type="button" onClick={() => setShowMatchForm(false)}>×</button></div>
              <label>Opponent username<input name="opponent" required placeholder="@sameerj" /></label>
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
                {match.status === "pending" && currentParticipant && !currentParticipant.is_submitter && <button type="button" disabled={busy} onClick={() => void confirmMatch(match.id)}>Confirm</button>}
              </article>;
            })}
          </div>
        </div>
      )}
    </section>
  );
}
