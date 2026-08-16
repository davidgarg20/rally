export type Venue = {
  id: string;
  name: string;
  area: string;
  city: string;
  distance_km: number;
  courts: number;
  hourly_rate: number;
  players_at_level: number;
  rated_night: string | null;
  slots: string[];
};

export const venueFixtures: Venue[] = [
  { id: "smash-arena", name: "Smash Arena", area: "HSR Layout · Sector 2", city: "BLR", distance_km: 1.4, courts: 6, hourly_rate: 450, players_at_level: 18, rated_night: "Saturday", slots: ["Today, 7:30 PM", "Today, 9:00 PM", "Tomorrow, 8:00 PM"] },
  { id: "padukone-dravid-centre", name: "Padukone-Dravid Centre", area: "Koramangala", city: "BLR", distance_km: 2.1, courts: 12, hourly_rate: 600, players_at_level: 34, rated_night: "Thursday", slots: ["Today, 8:00 PM", "Tomorrow, 6:30 AM", "Tomorrow, 7:30 PM"] },
  { id: "nimbus-badminton-club", name: "Nimbus Badminton Club", area: "Koramangala 5th Block", city: "BLR", distance_km: 3.2, courts: 8, hourly_rate: 400, players_at_level: 11, rated_night: null, slots: ["Today, 9:00 PM", "Tomorrow, 7:00 AM", "Tuesday, 8:00 PM"] },
  { id: "play-arena", name: "Play Arena", area: "Sarjapur Road", city: "BLR", distance_km: 4.8, courts: 10, hourly_rate: 550, players_at_level: 9, rated_night: null, slots: ["Tomorrow, 6:30 AM", "Tomorrow, 9:00 PM", "Wednesday, 8:00 PM"] },
  { id: "shuttle-hub", name: "Shuttle Hub", area: "Indiranagar", city: "BLR", distance_km: 6.4, courts: 5, hourly_rate: 500, players_at_level: 14, rated_night: "Tuesday", slots: ["Tuesday, 7:00 PM", "Tuesday, 8:30 PM", "Thursday, 7:30 PM"] },
];
