import type { Metadata } from "next";
import "./globals.css";

const siteUrl = new URL("https://davidgarg20.github.io/rally/");
const title = "Rally — Your badminton rating";
const description =
  "The universal skill rating and AI video coach for amateur badminton players. Log matches, understand your game and rise together.";

export const metadata: Metadata = {
  metadataBase: siteUrl,
  title,
  description,
  icons: {
    icon: new URL("favicon.svg", siteUrl).toString(),
    shortcut: new URL("favicon.svg", siteUrl).toString(),
  },
  openGraph: {
    title,
    description,
    type: "website",
    url: siteUrl,
    images: [
      {
        url: new URL("og.png", siteUrl).toString(),
        width: 1732,
        height: 909,
        alt: "Rally — Every player deserves a number",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title,
    description,
    images: [new URL("og.png", siteUrl).toString()],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
