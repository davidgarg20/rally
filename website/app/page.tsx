"use client";

import { FormEvent, useEffect, useState } from "react";
import RallyApp from "./rally-app";
import { venueFixtures } from "./venues";

const appEnabled = import.meta.env.DEV || Boolean(import.meta.env.VITE_RALLY_API_URL);
const dashboardView = "dashboard";

const leaderboard = {
  City: [
    ["1", "Vikram R.", "Indiranagar", "2042", "+22"],
    ["2", "Ananya S.", "Koramangala", "1988", "+14"],
    ["3", "Rohit K.", "HSR Layout", "1946", "+31"],
    ["4", "Meera N.", "Whitefield", "1902", "+9"],
  ],
  Club: [
    ["1", "Arjun P.", "PDC", "1874", "+20"],
    ["2", "Sameer J.", "PDC", "1816", "+12"],
    ["3", "Neha A.", "PDC", "1763", "+17"],
    ["4", "Karan M.", "PDC", "1719", "+6"],
  ],
  Friends: [
    ["1", "Arjun P.", "Your circle", "1578", "+24"],
    ["2", "Riya T.", "Your circle", "1546", "+27"],
    ["3", "Kabir D.", "Your circle", "1512", "+8"],
    ["4", "Nisha V.", "Your circle", "1479", "+19"],
  ],
};

export default function Home() {
  const [board, setBoard] = useState<keyof typeof leaderboard>("City");
  const [joined, setJoined] = useState(false);
  const [appOpen, setAppOpen] = useState(false);
  const [preferredVenueId, setPreferredVenueId] = useState<string | null>(null);

  useEffect(() => {
    const syncAppWithUrl = () => {
      setAppOpen(new URLSearchParams(window.location.search).get("view") === dashboardView);
    };
    const timer = window.setTimeout(syncAppWithUrl, 0);
    window.addEventListener("popstate", syncAppWithUrl);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("popstate", syncAppWithUrl);
    };
  }, []);

  function submitWaitlist(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setJoined(true);
  }

  function openApp() {
    const url = new URL(window.location.href);
    if (url.searchParams.get("view") !== dashboardView) {
      url.searchParams.set("view", dashboardView);
      window.history.pushState({ ...window.history.state, rallyView: dashboardView }, "", url);
    }
    setAppOpen(true);
  }

  function closeApp() {
    const url = new URL(window.location.href);
    url.searchParams.delete("view");
    window.history.replaceState({ ...window.history.state, rallyView: undefined }, "", url);
    setPreferredVenueId(null);
    setAppOpen(false);
  }

  function openVenue(venueId: string) {
    setPreferredVenueId(venueId);
    openApp();
  }

  return (
    <main>
      <nav className="nav-shell" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="Rally home">
          <span className="brand-mark" aria-hidden="true">↗</span>
          <span>RALLY</span>
        </a>
        <div className="nav-links">
          <a href="#how">How it works</a>
          <a href="#ai-coach">AI Coach</a>
          <a href="#community">Leaderboards</a>
          <a href="#venues">Courts</a>
          <a href="#organizers">For organizers</a>
          {appEnabled ? (
            <button className="nav-cta nav-app-button" type="button" onClick={openApp}>Open Rally</button>
          ) : (
            <a className="nav-cta" href="#waitlist">Join early access</a>
          )}
        </div>
      </nav>

      <section className="hero" id="top">
        <div className="hero-copy">
          <div className="eyebrow"><span /> Bangalore, you&apos;re up first</div>
          <h1>Every player<br />deserves a <em>number.</em></h1>
          <p className="hero-lede">
            Rally is the universal skill rating for badminton. Log a match,
            validate the score and discover who&apos;s really at your level.
          </p>
          <div className="hero-actions">
            {appEnabled ? (
              <button className="button primary hero-app-button" type="button" onClick={openApp}>Get your Rally rating <span>↗</span></button>
            ) : (
              <a className="button primary" href="#waitlist">Get your Rally rating <span>↗</span></a>
            )}
            <a className="text-link" href="#how">See how it works <span>↓</span></a>
          </div>
          <div className="hero-proof">
            <div className="avatar-stack" aria-hidden="true">
              <span>AK</span><span>SM</span><span>RJ</span><span>+</span>
            </div>
            <p><strong>Built for the 200M+</strong><br />amateur players the rankings forgot.</p>
          </div>
        </div>

        <div className="hero-visual" aria-label="Rally player rating preview">
          <div className="court-lines" aria-hidden="true" />
          <div className="rating-orbit orbit-one">+24</div>
          <div className="rating-orbit orbit-two">#12 BLR</div>
          <div className="phone-card">
            <div className="phone-top"><span>9:41</span><span>● ●●</span></div>
            <div className="app-heading"><span>Good morning, Arjun</span><b>•••</b></div>
            <div className="rating-panel">
              <span className="tiny-label">YOUR RALLY RATING</span>
              <strong>1578</strong>
              <div className="rating-meta"><span>↗ 24 this month</span><span>Reliable ●</span></div>
              <div className="rating-bars" aria-hidden="true">
                <i /><i /><i /><i /><i /><i /><i /><i /><i />
              </div>
            </div>
            <div className="next-match">
              <div><span className="tiny-label">NEXT MATCH</span><b>Koramangala • Today, 7:30 PM</b></div>
              <span className="round-arrow">→</span>
            </div>
            <div className="recent-title"><b>Recent form</b><span>View all</span></div>
            <div className="match-row"><span className="win">W</span><div><b>vs. Sameer &amp; Rohan</b><small>21–17, 19–21, 21–16</small></div><strong>+18</strong></div>
            <div className="match-row"><span className="win">W</span><div><b>vs. Neha &amp; Vikram</b><small>21–14, 21–18</small></div><strong>+11</strong></div>
          </div>
        </div>
      </section>

      <section className="signal-strip" aria-label="Rally at a glance">
        <div><strong>200M+</strong><span>amateur players worldwide</span></div>
        <div><strong>1500</strong><span>Glicko-2 starting rating</span></div>
        <div><strong>72h</strong><span>score validation window</span></div>
        <div><strong>5km</strong><span>level-based discovery radius</span></div>
      </section>

      <section className="problem-section section-pad">
        <div className="section-kicker lime">The gap in the game</div>
        <div className="problem-grid">
          <h2>Skill is everywhere.<br /><em>Clarity isn&apos;t.</em></h2>
          <div className="problem-copy">
            <p>Badminton is one of the world&apos;s most played sports, yet recreational players still describe themselves as “intermediate-ish.” Rankings stop at tournaments. The rest of us are left guessing.</p>
            <p>Rally turns every validated match into a living, portable rating—so your number follows you from your society court to your club, city and beyond.</p>
          </div>
        </div>
        <div className="statement-line"><span>ONE NUMBER.</span><span>ANY COURT.</span><span>ANYWHERE.</span></div>
      </section>

      <section className="how-section section-pad" id="how">
        <div className="section-heading">
          <div><div className="section-kicker">How Rally works</div><h2>Play. Prove it.<br />Find your level.</h2></div>
          <p>Every player begins at 1500. Built on Glicko-2, Rally tracks rating uncertainty and gets sharper with each validated match—even when your local badminton world is small.</p>
        </div>
        <div className="steps-grid">
          <article className="step-card step-dark">
            <div className="step-top"><span>01</span><span className="step-icon">＋</span></div>
            <div className="score-ticket"><b>21</b><span>:</span><b>17</b><small>GAME 3 • FINAL</small></div>
            <h3>Log the score</h3><p>Add a singles or doubles match in under 30 seconds.</p>
          </article>
          <article className="step-card step-lime">
            <div className="step-top"><span>02</span><span className="step-icon">✓</span></div>
            <div className="verify-stack"><span>Score posted</span><span>Opponent confirmed</span><b>Match validated</b></div>
            <h3>Validate together</h3><p>Your opponent confirms the result. No gatekeepers, no guesswork.</p>
          </article>
          <article className="step-card step-paper">
            <div className="step-top"><span>03</span><span className="step-icon">↗</span></div>
            <div className="number-jump"><small>NEW RATING</small><strong>1578</strong><span>+24</span></div>
            <h3>Watch your rating move</h3><p>See exactly how every performance shapes your Rally number.</p>
          </article>
        </div>
      </section>

      <section className="ai-coach-section section-pad" id="ai-coach">
        <div className="ai-coach-head">
          <div>
            <div className="section-kicker lime">Rally AI Coach · In development</div>
            <h2>Your rating says <em>where.</em><br />AI shows you <em>why.</em></h2>
          </div>
          <div className="ai-coach-intro">
            <p>Record a drill or match on your phone. Rally reads movement, shot patterns and recovery to turn footage into clear, evidence-backed coaching.</p>
            <a className="button ai-coach-button" href="#waitlist">Join AI Coach early access <span>↗</span></a>
          </div>
        </div>

        <div className="ai-coach-stage">
          <div className="vision-card">
            <div className="vision-head"><span>SESSION 04 · SINGLES</span><b>ANALYSING</b></div>
            <div className="vision-court" aria-label="Illustration of Rally analysing badminton footage">
              <div className="vision-lines" aria-hidden="true" />
              <div className="vision-player" aria-hidden="true"><i /><i /><i /><i /><i /><i /></div>
              <div className="vision-shuttle" aria-hidden="true" />
              <div className="vision-tag tag-contact">Contact height · Good</div>
              <div className="vision-tag tag-recovery">Base recovery · 1.4s</div>
              <div className="vision-scan" aria-hidden="true" />
            </div>
            <div className="vision-timeline"><span /><span /><b>SMASH DETECTED · 00:14.2</b></div>
          </div>

          <div className="skill-card">
            <div className="skill-card-head"><div><small>VIDEO-DERIVED</small><h3>Skill DNA</h3></div><span>82% confidence</span></div>
            <div className="skill-row"><span>Power</span><i><b style={{width: "74%"}} /></i><strong>74</strong></div>
            <div className="skill-row"><span>Placement</span><i><b style={{width: "63%"}} /></i><strong>63</strong></div>
            <div className="skill-row"><span>Footwork</span><i><b style={{width: "68%"}} /></i><strong>68</strong></div>
            <div className="skill-row"><span>Defense</span><i><b style={{width: "71%"}} /></i><strong>71</strong></div>
            <div className="skill-row"><span>Consistency</span><i><b style={{width: "56%"}} /></i><strong>56</strong></div>
            <div className="coach-focus"><small>YOUR NEXT FOCUS</small><b>Prepare the split step earlier.</b><p>You recovered late after 6 of 10 attacking shots. Start your split step as your opponent makes contact.</p><span>3 clips support this insight →</span></div>
          </div>
        </div>

        <div className="ai-capability-grid">
          <article><span>01</span><h3>Smash mechanics</h3><p>Review contact timing, shoulder and hip rotation, follow-through and recovery—not just an unreliable speed estimate.</p></article>
          <article><span>02</span><h3>Drop control</h3><p>See approximate placement, consistency and how effectively the same preparation hides your softer shots.</p></article>
          <article><span>03</span><h3>Footwork &amp; weaknesses</h3><p>Map movement, split-step timing, late contacts and the court zones where rallies most often break down.</p></article>
        </div>

        <div className="ai-coach-footer">
          <div><b>1</b><span>Record a drill<br />or full match</span></div><i>→</i>
          <div><b>2</b><span>Vision measures<br />movement &amp; shots</span></div><i>→</i>
          <div><b>3</b><span>AI explains<br />what to train next</span></div>
          <p><strong>Kept separate by design.</strong> AI Skill DNA explains your game; only validated match results shape your Rally rating. Every insight includes a confidence level.</p>
        </div>
      </section>

      <section className="level-section section-pad">
        <div className="section-kicker">A shared language for skill</div>
        <div className="level-head"><h2>Know where you stand.<br /><em>Know where to go.</em></h2><p>Your Glicko-2 rating starts at 1500 and becomes more reliable as you play. Skill bands keep the number easy to understand—and the next milestone within reach.</p></div>
        <div className="level-track">
          <div className="track-line"><i style={{left: "55%"}} /><span style={{left: "55%"}}>YOU • 1578</span></div>
          <div className="level-labels"><span><b>&lt;1200</b>Beginner</span><span><b>1200</b>Developing</span><span><b>1500</b>Competitive</span><span><b>1800</b>Advanced</span><span><b>2100+</b>Elite</span></div>
        </div>
      </section>

      <section className="leaderboard-section section-pad" id="community">
        <div className="leaderboard-copy">
          <div className="section-kicker lime">Your game gets bigger</div>
          <h2>A leaderboard that feels <em>local.</em></h2>
          <p>See where you stand across your city, club and friend group. Find the players one step above you—and the match that can take you there.</p>
          <ul className="feature-list">
            <li><span>◎</span><div><b>Find players at your level</b><small>Discover reliable partners nearby, not random profiles.</small></div></li>
            <li><span>⌁</span><div><b>Build a real playing circle</b><small>Follow friends, rivals and the local players pushing you.</small></div></li>
            <li><span>✦</span><div><b>Make every match matter</b><small>Form, streaks and progress—without turning play into pressure.</small></div></li>
          </ul>
        </div>
        <div className="board-card">
          <div className="board-head"><div><small>BANGALORE</small><h3>Leaderboard</h3></div><span>LIVE PREVIEW</span></div>
          <div className="board-tabs" role="tablist" aria-label="Leaderboard view">
            {(Object.keys(leaderboard) as Array<keyof typeof leaderboard>).map((tab) => <button key={tab} className={board === tab ? "active" : ""} onClick={() => setBoard(tab)} role="tab" aria-selected={board === tab}>{tab}</button>)}
          </div>
          <div className="board-labels"><span>RANK / PLAYER</span><span>RATING</span></div>
          <div className="board-rows">
            {leaderboard[board].map(([rank, name, area, rating, delta], index) => (
              <div className="board-row" key={name}>
                <span className="rank">{rank}</span><span className={`player-dot dot-${index + 1}`}>{name.split(" ").map((n) => n[0]).join("")}</span>
                <div className="player-name"><b>{name}</b><small>{area}</small></div><div className="player-rating"><b>{rating}</b><small>{delta}</small></div>
              </div>
            ))}
          </div>
          <div className="board-you"><span className="rank">12</span><span className="player-dot you-dot">YOU</span><div className="player-name"><b>You&apos;re closer than you think.</b><small>Play two more matches to climb.</small></div><div className="player-rating"><b>1578</b><small>+24</small></div></div>
        </div>
      </section>

      <section className="venue-section section-pad" id="venues">
        <div className="venue-section-head">
          <div>
            <div className="section-kicker lime">Courts near you</div>
            <h2>Pick a court.<br /><em>Find your game.</em></h2>
          </div>
          <div className="venue-section-intro">
            <p>See nearby badminton venues, hourly prices, rated-night schedules and how many players around your level already play there.</p>
            <span>Venue listings are free. Rally takes no cut from court fees.</span>
          </div>
        </div>
        <div className="venue-grid">
          {venueFixtures.map((venue, index) => (
            <article className={`venue-card ${index === 0 ? "featured" : ""}`} key={venue.id}>
              <div className="venue-card-top"><span>{String(index + 1).padStart(2, "0")}</span>{venue.rated_night && <b>RATED NIGHT · {venue.rated_night.toUpperCase()}</b>}</div>
              <h3>{venue.name}</h3>
              <p>{venue.area}</p>
              <div className="venue-stats"><span><b>{venue.distance_km} km</b>away</span><span><b>{venue.courts}</b>courts</span><span><b>₹{venue.hourly_rate}</b>per hour</span></div>
              <div className="venue-level"><strong>{venue.players_at_level}</strong><span>players near<br />your level</span></div>
              {appEnabled ? (
                <button type="button" onClick={() => openVenue(venue.id)}>Play here <span>↗</span></button>
              ) : (
                <a href="#waitlist">Join early access <span>↗</span></a>
              )}
            </article>
          ))}
        </div>
      </section>

      <section className="feature-bento section-pad">
        <article className="bento-intro"><div className="section-kicker">More than a number</div><h2>Your whole badminton life, <em>connected.</em></h2><p>One home for the matches you play, the people you meet and the progress you earn.</p></article>
        <article className="bento-card partner-card"><span className="bento-num">01</span><div className="radar"><i /><i /><i /><i /><b>YOU</b></div><h3>Find your next game</h3><p>Discover well-matched players within 5km, with real ratings and recent activity.</p></article>
        <article className="bento-card history-card"><span className="bento-num">02</span><div className="mini-chart"><span>4.3</span><i /><i /><i /><i /><i /><i /></div><h3>Your progress, made visible</h3><p>Track rating movement, recent form, streaks and every match behind the number.</p></article>
        <article className="bento-card event-card"><span className="bento-num">03</span><div className="event-ticket"><small>BLR OPEN • OCT 12</small><b>64 PLAYERS</b><span>Entries opening soon ↗</span></div><h3>Compete when you&apos;re ready</h3><p>Enter level-based tournaments where the draw is fair and every result counts.</p></article>
      </section>

      <section className="organizer-section" id="organizers">
        <div className="organizer-art" aria-hidden="true"><div className="court-orbit"><span>CLUBS</span><span>LEAGUES</span><span>OPENS</span><b>R</b></div></div>
        <div className="organizer-copy">
          <div className="section-kicker lime">For clubs &amp; organizers</div>
          <h2>Run better badminton.<br /><em>Grow the game.</em></h2>
          <p>Ratings, registrations, draws, score reporting and live standings—all in one clean system. Rally gives every event a professional layer without adding operational weight.</p>
          <div className="organizer-points"><span>✓ Level-based draws</span><span>✓ Live standings</span><span>✓ Automatic rating updates</span><span>✓ Player onboarding</span></div>
          <a className="button lime-button" href="#waitlist">Bring Rally to your venue <span>↗</span></a>
        </div>
      </section>

      <section className="quote-section">
        <div className="quote-mark">“</div>
        <blockquote>There are millions of brilliant players the sport has never learned how to <em>see.</em></blockquote>
        <p>Rally exists to change that—starting one court at a time.</p>
      </section>

      <section className="waitlist-section section-pad" id="waitlist">
        <div className="waitlist-copy"><div className="section-kicker">Launching first in Bangalore</div><h2>Your next match could be the start of your <em>number.</em></h2><p>Join the first Rally players and get early access, local play sessions and launch updates.</p></div>
        <div className="waitlist-card">
          {joined ? (
            <div className="success-state" role="status"><span>✓</span><h3>You&apos;re on the Rally.</h3><p>We&apos;ll be in touch when early access opens in Bangalore. Until then—keep playing.</p><button onClick={() => setJoined(false)}>Add another player</button></div>
          ) : (
            <form onSubmit={submitWaitlist}>
              <label>YOUR NAME<input name="name" type="text" placeholder="Arjun Mehta" required autoComplete="name" /></label>
              <label>EMAIL ADDRESS<input name="email" type="email" placeholder="arjun@example.com" required autoComplete="email" /></label>
              <label>I&apos;M JOINING AS<select name="role" defaultValue="Player"><option>Player</option><option>Club or venue</option><option>Tournament organizer</option><option>Coach</option></select></label>
              <button className="button form-button" type="submit">Join early access <span>↗</span></button>
              <small>No spam. Just useful launch updates and first access.</small>
            </form>
          )}
        </div>
      </section>

      <section className="faq-section section-pad">
        <div><div className="section-kicker">Good questions</div><h2>Before you<br /><em>step on court.</em></h2></div>
        <div className="faq-list">
          <details><summary>How do I get my first rating?<span>＋</span></summary><p>Every player begins at 1500 with a high rating deviation. Play and log a match against another Rally player; once your opponent validates the score, Glicko-2 updates both your rating and its reliability.</p></details>
          <details><summary>Can I use Rally for doubles?<span>＋</span></summary><p>Yes. Rally is designed for both singles and doubles, the way amateur badminton is actually played.</p></details>
          <details><summary>What stops someone posting a fake score?<span>＋</span></summary><p>Every self-posted match needs confirmation from the opposing side. Players have a 72-hour window to validate or dispute the result.</p></details>
          <details><summary>Is Rally only for advanced players?<span>＋</span></summary><p>Not at all. Rally is most useful when it includes every level, from a first regular game to the strongest club competitors.</p></details>
        </div>
      </section>

      <footer>
        <a className="brand footer-brand" href="#top"><span className="brand-mark">↗</span><span>RALLY</span></a>
        <p>The universal skill rating for badminton.<br />Bangalore first. The world next.</p>
        <div className="footer-links"><a href="#how">How it works</a><a href="#community">Leaderboards</a><a href="#organizers">Organizers</a><a href="#waitlist">Early access</a></div>
        <div className="footer-bottom"><span>© 2026 Rally</span><span>Built for the game we love.</span></div>
      </footer>
      {appEnabled && <RallyApp open={appOpen} onClose={closeApp} preferredVenueId={preferredVenueId} />}
    </main>
  );
}
