#inject shaders/chunks/Constants.glsl


varying vec2 vUv;

uniform sampler2D tPrev;
uniform sampler2D tCurr;
uniform float uDeltaT;
uniform float uTime;
uniform vec3 uInputPos[4];
uniform vec4 uInputPosFlag;

void main() {

    // read data
    vec3 prevPos = texture2D(tPrev, vUv).rgb;
    vec3 currPos = texture2D(tCurr, vUv).rgb;
    vec3 vel = (currPos - prevPos) / uDeltaT;

    // CALC ACCEL

    vec3 accel = vec3(0.0);

    // target shape
    {
        // sphere, continuous along vUv.y
        vec2 coords = vUv;
        coords.x = coords.x * M_2PI - M_PI; // theta (lat)
        coords.y = coords.y * M_PI;         // phi (long)
        vec3 sphereCoords = vec3(
            sin(coords.y) * cos(coords.x),
            cos(coords.y),
            sin(coords.y) * sin(coords.x)
        );

        float r = 1.0;
        vec3 targetPos = r * sphereCoords;
        targetPos *= 2.0;

        vec3 toCenter = targetPos - currPos;
        float toCenterLength = length(toCenter);
        if (!EQUALSZERO(toCenterLength))
            accel += K_TARGET_ACCEL * toCenter/toCenterLength;
    }

    // input pos

    #define PROCESS_INPUT_POS(FLAG, POS) if ((FLAG) != 0.0) { vec3 toCenter = (POS)-currPos; float toCenterLength = length(toCenter); accel += (toCenter/toCenterLength) * (FLAG)*K_INPUT_ACCEL/toCenterLength; }

    PROCESS_INPUT_POS(uInputPosFlag.x, uInputPos[0]);
    #ifdef MULTIPLE_INPUT
        PROCESS_INPUT_POS(uInputPosFlag.y, uInputPos[1]);
        PROCESS_INPUT_POS(uInputPosFlag.z, uInputPos[2]);
        PROCESS_INPUT_POS(uInputPosFlag.w, uInputPos[3]);
    #endif

    // state updates
    vel = K_VEL_DECAY * vel + accel * uDeltaT;
    currPos += vel * uDeltaT;

    // write out
    gl_FragColor = vec4(currPos, 1.0);
}