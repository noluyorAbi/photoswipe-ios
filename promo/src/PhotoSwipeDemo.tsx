import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";

// Brand palette (mirrors the app's Theme.swift)
const C = {
  bg0: "#0A0A10",
  bg1: "#12121A",
  keep: "#2BD980",
  trash: "#FF4D6D",
  fav: "#FFC23D",
  album: "#6E8BFF",
  purple: "#B88CFF",
  dim: "rgba(255,255,255,0.55)",
};

const FONT = '"SF Pro Rounded", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

type Scene = {
  s: number;
  e: number;
  title: string;
  sub: string;
  accent: string;
  img: string;
};

const SCENES: Scene[] = [
  { s: 0, e: 112, title: "Clean your\ncamera roll.", sub: "Swipe through thousands of photos — fast.", accent: C.album, img: "01-picker.png" },
  { s: 112, e: 225, title: "Swipe to sort.", sub: "Left trash · Right keep · Up favorite", accent: C.keep, img: "02-swipe.png" },
  { s: 225, e: 338, title: "Find duplicates.", sub: "On-device. Automatic. Private.", accent: C.purple, img: "03-duplicates.png" },
  { s: 338, e: 450, title: "Free up storage.", sub: "See exactly how much you saved.", accent: C.trash, img: "04-review.png" },
];

const fadeWindow = (frame: number, s: number, e: number, dur = 14) =>
  interpolate(frame, [s, s + dur, e - dur, e], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

const Aurora: React.FC = () => {
  const frame = useCurrentFrame();
  const t = frame / 30;
  const blob = (color: string, x: number, y: number, size: number, phase: number) => {
    const dx = Math.sin(t * 0.5 + phase) * 40;
    const dy = Math.cos(t * 0.4 + phase) * 36;
    return (
      <div
        style={{
          position: "absolute",
          left: x + dx,
          top: y + dy,
          width: size,
          height: size,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${color}33 0%, transparent 70%)`,
          filter: "blur(40px)",
        }}
      />
    );
  };
  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, ${C.bg1}, ${C.bg0})` }}>
      {blob(C.album, -80, -120, 620, 0)}
      {blob(C.keep, 820, 360, 560, 2)}
      {blob(C.fav, 980, -160, 420, 4)}
    </AbsoluteFill>
  );
};

const PhoneFrame: React.FC<{ accent: string }> = ({ accent }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pw = 272;
  const ph = 590;
  return (
    <div
      style={{
        position: "absolute",
        right: 110,
        top: (720 - ph) / 2,
        width: pw,
        height: ph,
        borderRadius: 46,
        background: "#000",
        border: "2px solid rgba(255,255,255,0.10)",
        boxShadow: `0 40px 90px rgba(0,0,0,0.6), 0 0 60px ${accent}22`,
        padding: 9,
      }}
    >
      <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: 38, overflow: "hidden", background: C.bg0 }}>
        {SCENES.map((sc, i) => {
          // Overlap neighbouring windows so the screen cross-fades (no black gap).
          const op = fadeWindow(frame, sc.s - 12, sc.e + 12, 24);
          const enter = spring({ frame: frame - sc.s, fps, config: { damping: 200 } });
          const x = interpolate(enter, [0, 1], [40, 0]);
          return (
            <Img
              key={i}
              src={staticFile(sc.img)}
              style={{
                position: "absolute",
                inset: 0,
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: op,
                transform: `translateX(${x}px)`,
              }}
            />
          );
        })}
      </div>
    </div>
  );
};

const Headlines: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return (
    <>
      {SCENES.map((sc, i) => {
        const op = fadeWindow(frame, sc.s, sc.e, 12);
        const enter = spring({ frame: frame - sc.s, fps, config: { damping: 200 } });
        const y = interpolate(enter, [0, 1], [26, 0]);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 84,
              top: 250,
              width: 600,
              opacity: op,
              transform: `translateY(${y}px)`,
            }}
          >
            <div
              style={{
                display: "inline-block",
                fontFamily: FONT,
                fontSize: 17,
                fontWeight: 700,
                letterSpacing: 2,
                color: sc.accent,
                marginBottom: 14,
                padding: "6px 14px",
                borderRadius: 999,
                background: `${sc.accent}1f`,
              }}
            >
              {String(i + 1).padStart(2, "0")} / 04
            </div>
            <div
              style={{
                fontFamily: FONT,
                fontSize: 72,
                fontWeight: 800,
                lineHeight: 1.02,
                color: "#fff",
                whiteSpace: "pre-line",
                letterSpacing: -1,
              }}
            >
              {sc.title}
            </div>
            <div style={{ fontFamily: FONT, fontSize: 26, fontWeight: 500, color: C.dim, marginTop: 18 }}>
              {sc.sub}
            </div>
          </div>
        );
      })}
    </>
  );
};

const Brand: React.FC = () => {
  const frame = useCurrentFrame();
  const op = interpolate(frame, [0, 18], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 84, top: 70, display: "flex", alignItems: "center", gap: 16, opacity: op }}>
      <Img src={staticFile("icon.png")} style={{ width: 64, height: 64, borderRadius: 16 }} />
      <div style={{ fontFamily: FONT, fontSize: 34, fontWeight: 800, color: "#fff" }}>PhotoSwipe</div>
    </div>
  );
};

const Footer: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const outro = spring({ frame: frame - 392, fps, config: { damping: 200 } });
  const scale = interpolate(outro, [0, 1], [1, 1.12]);
  const glow = interpolate(outro, [0, 1], [0, 1]);
  const op = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div
      style={{
        position: "absolute",
        left: 84,
        bottom: 60,
        opacity: op,
        transform: `scale(${scale})`,
        transformOrigin: "left center",
        display: "flex",
        alignItems: "center",
        gap: 12,
        fontFamily: FONT,
      }}
    >
      <div style={{ fontSize: 22, color: C.keep, fontWeight: 800 }}>★ Open source</div>
      <div style={{ fontSize: 22, color: "#fff", fontWeight: 600, textShadow: `0 0 ${20 * glow}px ${C.keep}` }}>
        github.com/noluyorAbi/photoswipe-ios
      </div>
    </div>
  );
};

export const PhotoSwipeDemo: React.FC = () => {
  const frame = useCurrentFrame();
  // gentle global fade-in/out
  const op = interpolate(frame, [0, 12, 438, 450], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const accent = SCENES.find((s) => frame >= s.s && frame < s.e)?.accent ?? C.album;
  return (
    <AbsoluteFill style={{ opacity: op }}>
      <Aurora />
      <Brand />
      <Headlines />
      <PhoneFrame accent={accent} />
      <Footer />
    </AbsoluteFill>
  );
};
