import { Composition } from "remotion";
import { PhotoSwipeDemo } from "./PhotoSwipeDemo";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="PhotoSwipeDemo"
      component={PhotoSwipeDemo}
      durationInFrames={450}
      fps={30}
      width={1280}
      height={720}
    />
  );
};
