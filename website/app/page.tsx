"use client";

import { FormEvent, useState } from "react";

const leaderboard = {
  City: [
    ["1", "Vikram R.", "Indiranagar", "5.6214", "+0.18"],
    ["2", "Ananya S.", "Koramangala", "5.4872", "+0.09"],
    ["3", "Rohit K.", "HSR Layout", "5.3918", "+0.23"],
    ["4", "Meera N.", "Whitefield", "5.2741", "+0.06"],
  ],
  Club: [
    ["1", "Arjun P.", "PDC", "5.1023", "+0.14"],
    ["2", "Sameer J.", "PDC", "4.9817", "+0.08"],
    ["3", "Neha A.", "PDC", "4.8742", "+0.11"],
    ["4", "Karan M.", "PDC", "4.7689", "+0.03"],
  ],
  Friends: [
    ["1", "Arjun P.", "Your circle", "4.2871", "+0.12"],
    ["2", "Riya T.", "Your circle", "4.2108", "+0.17"],
    ["3", "Kabir D.", "Your circle", "4.0873", "+0.04"],
    ["4", "Nisha V.", "Your circle", "3.9941", "+0.15"],
  ],
};

export default function Home() {
  const [board, setBoard] = useState<keyof typeof leaderboard>("City");
  const [joined, setJoined] = useState(false);

  function submitWaitlist(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setJoined(true);
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
          <a href="#community">Leaderboards</a>
          <a href="#organizers">For organizers</a>
          <a className="nav-cta" href="#waitlist">Join early access</a>
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
            <a className="button primary" href="#waitlist">Get your Rally rating <span>↗</span></a>
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
          <div className="rating-orbit orbit-one">+0.12</div>
          <div className="rating-orbit orbit-two">#12 BLR</div>
          <div className="phone-card">
            <div className="phone-top"><span>9:41</span><span>● ●●</span></div>
            <div className="app-heading"><span>Good morning, Arjun</span><b>•••</b></div>
            <div className="rating-panel">
              <span className="tiny-label">YOUR RALLY RATING</span>
              <strong>4.2871</strong>
              <div className="rating-meta"><span>↗ 0.12 this month</span><span>Reliable ●</span></div>
              <div className="rating-bars" aria-hidden="true">
                <i /><i /><i /><i /><i /><i /><i /><i /><i />
              </div>
            </div>
            <div className="next-match">
              <div><span className="tiny-label">NEXT MATCH</span><b>Koramangala • Today, 7:30 PM</b></div>
              <span className="round-arrow">→</span>
            </div>
            <div className="recent-title"><b>Recent form</b><span>View all</span></div>
            <div className="match-row"><span className="win">W</span><div><b>vs. Sameer &amp; Rohan</b><small>21–17, 19–21, 21–16</small></div><strong>+0.08</strong></div>
            <div className="match-row"><span className="win">W</span><div><b>vs. Neha &amp; Vikram</b><small>21–14, 21–18</small></div><strong>+0.04</strong></div>
          </div>
        </div>
      </section>

      <section className="signal-strip" aria-label="Rally at a glance">
        <div><strong>200M+</strong><span>amateur players worldwide</span></div>
        <div><strong>1</strong><span>validated match to start</span></div>
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
          <p>Built on Glicko-2, Rally gets sharper as you play. It understands uncertainty, rewards consistent results and works even when your local badminton world is small.</p>
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
            <div className="number-jump"><small>NEW RATING</small><strong>4.2871</strong><span>+0.08</span></div>
            <h3>Watch your rating move</h3><p>See exactly how every performance shapes your Rally number.</p>
          </article>
        </div>
      </section>

      <section className="level-section section-pad">
        <div className="section-kicker">A shared language for skill</div>
        <div className="level-head"><h2>Know where you stand.<br /><em>Know where to go.</em></h2><p>Your rating is precise, but the experience is human. Rally makes every level easier to understand—and the next one feel within reach.</p></div>
        <div className="level-track">
          <div className="track-line"><i style={{left: "55%"}} /><span style={{left: "55%"}}>YOU • 4.2871</span></div>
          <div className="level-labels"><span><b>1.0</b>Beginner</span><span><b>2.5</b>Developing</span><span><b>4.0</b>Competitive</span><span><b>5.5</b>Advanced</span><span><b>7.0</b>Elite</span></div>
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
          <div className="board-you"><span className="rank">12</span><span className="player-dot you-dot">YOU</span><div className="player-name"><b>You&apos;re closer than you think.</b><small>Play two more matches to climb.</small></div><div className="player-rating"><b>4.2871</b><small>+0.12</small></div></div>
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
          <details><summary>How do I get my first rating?<span>＋</span></summary><p>Play and log one match against another Rally player. Once your opponent validates the score, you&apos;ll receive a starting rating that becomes more reliable with every result.</p></details>
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
    </main>
  );
}
