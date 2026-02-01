// Nexiom FFmpeg WebAssembly bridge
// This file exposes a simple API on window.NexiomFFmpeg
// to be consumed from Flutter Web via package:js/js.dart.

(function (global) {
  // Ensure FFmpeg global is available
  if (!global.FFmpeg) {
    console.error('FFmpeg global not found. Make sure ffmpeg.min.js is loaded before ffmpeg_bridge.js');
    return;
  }

  /**
   * Merge a video, an audio track, and a logo image into a final MP4.
   * The logo is overlaid in the specified corner with configurable size and opacity.
   *
   * @param {Uint8Array|ArrayBuffer|Blob} videoData
   * @param {Uint8Array|ArrayBuffer|Blob} audioData
   * @param {Uint8Array|ArrayBuffer|Blob} logoData
   * @param {string} [position] one of 'bottom_right', 'bottom_left', 'top_right', 'top_left'
   * @param {number} [size] relative logo width vs video width (0.05–0.5, default 0.2)
   * @param {number} [opacity] logo opacity (0.1–1.0, default 1.0)
   * @returns {Promise<ArrayBuffer>} bytes of the merged MP4 file
   */
  async function mergeVideoAudioLogo(
    videoData,
    audioData,
    logoData,
    position = 'bottom_right',
    size = 0.2,
    opacity = 1.0,
  ) {
    await ensureLoaded();

    try {
      const videoFile = await fetchFile(videoData);
      const audioFile = await fetchFile(audioData);
      const logoFile = await fetchFile(logoData);

      ffmpeg.FS('writeFile', 'input_video.mp4', videoFile);
      ffmpeg.FS('writeFile', 'input_audio.mp3', audioFile);
      ffmpeg.FS('writeFile', 'logo.png', logoFile);

      const safeSize = Math.max(0.05, Math.min(size || 0.2, 0.5));
      const safeOpacity = Math.max(0.1, Math.min(opacity || 1.0, 1.0));

      let overlayExpr;
      switch (position) {
        case 'top_left':
          overlayExpr = 'overlay=20:20';
          break;
        case 'top_right':
          overlayExpr = 'overlay=W-w-20:20';
          break;
        case 'bottom_left':
          overlayExpr = 'overlay=20:H-h-20';
          break;
        case 'bottom_right':
        default:
          overlayExpr = 'overlay=W-w-20:H-h-20';
          break;
      }

      const filterComplex =
        `[1:v][0:v]scale2ref=w=main_w*${safeSize}:h=-2[logo][base];` +
        `[logo]format=rgba,colorchannelmixer=aa=${safeOpacity}[logoA];` +
        `[base][logoA]${overlayExpr}`;

      await ffmpeg.run(
        '-i', 'input_video.mp4',
        '-i', 'logo.png',
        '-i', 'input_audio.mp3',
        '-filter_complex', filterComplex,
        '-map', '0:v',
        '-map', '2:a',
        '-c:v', 'libx264',
        '-c:a', 'aac',
        'output.mp4',
      );

      const data = ffmpeg.FS('readFile', 'output.mp4');

      try {
        ffmpeg.FS('unlink', 'input_video.mp4');
        ffmpeg.FS('unlink', 'input_audio.mp3');
        ffmpeg.FS('unlink', 'logo.png');
        ffmpeg.FS('unlink', 'output.mp4');
      } catch (e) {
        // ignore cleanup errors
      }

      return data.buffer;
    } catch (e) {
      console.error('NexiomFFmpeg.mergeVideoAudioLogo error', e);
      throw e;
    }
  }

  const { createFFmpeg, fetchFile } = global.FFmpeg;

  const ffmpeg = createFFmpeg({ log: false });
  let loadPromise = null;

  async function ensureLoaded() {
    if (!loadPromise) {
      loadPromise = ffmpeg.load();
    }
    await loadPromise;
  }

  /**
   * Merge a video (H.264) and an audio track into a final MP4 with AAC audio.
   *
   * @param {Uint8Array|ArrayBuffer|Blob} videoData
   * @param {Uint8Array|ArrayBuffer|Blob} audioData
   * @returns {Promise<Uint8Array>} bytes of the merged MP4 file
   */
  async function mergeVideoAudio(videoData, audioData) {
    await ensureLoaded();

    try {
      // Normalize to something fetchFile accepts
      const videoFile = await fetchFile(videoData);
      const audioFile = await fetchFile(audioData);

      // Write inputs
      ffmpeg.FS('writeFile', 'input_video.mp4', videoFile);
      ffmpeg.FS('writeFile', 'input_audio.mp3', audioFile);

      // Run merge command as specified (H.264 + AAC in MP4)
      await ffmpeg.run(
        '-i', 'input_video.mp4',
        '-i', 'input_audio.mp3',
        '-c:v', 'copy',
        '-c:a', 'aac',
        '-map', '0:v:0',
        '-map', '1:a:0',
        'output.mp4',
      );

      const data = ffmpeg.FS('readFile', 'output.mp4');

      // Cleanup
      try {
        ffmpeg.FS('unlink', 'input_video.mp4');
        ffmpeg.FS('unlink', 'input_audio.mp3');
        ffmpeg.FS('unlink', 'output.mp4');
      } catch (e) {
        // ignore cleanup errors
      }

      // Return the underlying ArrayBuffer so that Dart can view it as a ByteBuffer
      return data.buffer;
    } catch (e) {
      console.error('NexiomFFmpeg.mergeVideoAudio error', e);
      throw e;
    }
  }
  async function composeSlideshow(imageDatas, durations, audioData) {
    await ensureLoaded();

    if (!Array.isArray(imageDatas) || !Array.isArray(durations)) {
      throw new Error('composeSlideshow: imageDatas and durations must be arrays');
    }

    const count = Math.min(imageDatas.length, durations.length);
    if (count === 0) {
      throw new Error('composeSlideshow: at least one image is required');
    }

    try {
      let slidesText = '';

      for (let i = 0; i < count; i++) {
        const imgFile = await fetchFile(imageDatas[i]);
        const fileName = `slide_${i}.png`;
        ffmpeg.FS('writeFile', fileName, imgFile);

        let d = Number(durations[i]);
        if (!Number.isFinite(d) || d <= 0) d = 1;
        slidesText += `file '${fileName}'\n`;
        slidesText += `duration ${d}\n`;
      }

      const lastFileName = `slide_${count - 1}.png`;
      slidesText += `file '${lastFileName}'\n`;

      const encoder = new TextEncoder();
      ffmpeg.FS('writeFile', 'slides.txt', encoder.encode(slidesText));

      await ffmpeg.run(
        '-f', 'concat',
        '-safe', '0',
        '-i', 'slides.txt',
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        'output.mp4',
      );

      const data = ffmpeg.FS('readFile', 'output.mp4');

      try {
        ffmpeg.FS('unlink', 'slides.txt');
        for (let i = 0; i < count; i++) {
          const fileName = `slide_${i}.png`;
          ffmpeg.FS('unlink', fileName);
        }
        ffmpeg.FS('unlink', 'output.mp4');
      } catch (e) {
      }

      return data.buffer;
    } catch (e) {
      console.error('NexiomFFmpeg.composeSlideshow error', e);
      throw e;
    }
  }

  global.NexiomFFmpeg = {
    mergeVideoAudio,
    mergeVideoAudioLogo,
    composeSlideshow,
  };
})(window);
