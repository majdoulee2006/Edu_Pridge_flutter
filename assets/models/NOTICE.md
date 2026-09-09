# mobile_face_net.tflite — Source & Provenance

- **File**: `mobile_face_net.tflite`
- **Downloaded from**: https://github.com/irhammuch/android-face-recognition
  (raw file: `app/src/main/assets/mobile_face_net.tflite`, commit as of 2026-09-09)
- **Architecture**: MobileFaceNet — input `112x112x3` RGB, normalized as `(pixel - 128) / 128`,
  output a `192`-dimensional face embedding vector.
- **Upstream training code / origin**: https://github.com/sirius-ai/MobileFaceNet_TF
  (licensed Apache-2.0). The `.tflite` conversion hosted in the `irhammuch` repo does not carry
  its own explicit LICENSE file, so the conversion/redistribution terms for that specific binary
  are not formally documented by its author. It is a widely reused artifact across several
  open-source Android/Flutter face-recognition sample apps.
- **Why we used it anyway**: no in-house training pipeline or GPU/dataset was available to
  reproduce and convert the model ourselves. This is a stop-gap tracked here explicitly so the
  provenance is never lost. If stricter licensing certainty is later required, re-derive a
  `.tflite` directly from the Apache-2.0 `sirius-ai/MobileFaceNet_TF` checkpoints instead of
  reusing this pre-converted file.
