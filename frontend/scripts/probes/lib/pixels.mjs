/**
 * Calculations over raw RGBA pixel bytes (an ImageData buffer decoded in the
 * page and handed back as base64). Used by ZG-12 to confirm a below-fold
 * section actually painted in a full-page screenshot.
 */

export const CHANNEL_THRESHOLD = 32;

// True when any RGB channel of the pixel differs from `bg` by more than `threshold`.
export function differsFrom(pixel, bg, threshold) {
  return Math.abs(pixel.r - bg.r) > threshold || Math.abs(pixel.g - bg.g) > threshold || Math.abs(pixel.b - bg.b) > threshold;
}

// Pixels in an RGBA byte buffer that differ from `bg` by more than `threshold`.
export function countDifferingPixels(bytes, bg, threshold) {
  let count = 0;
  for (let i = 0; i + 2 < bytes.length; i += 4) {
    if (differsFrom({ r: bytes[i], g: bytes[i + 1], b: bytes[i + 2] }, bg, threshold)) {
      count += 1;
    }
  }
  return count;
}
