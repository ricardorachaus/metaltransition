//
//  Doom.metal
//  DoomTransition
//
//  Created by Ricardo Rachaus on 18/11/22.
//

#include <metal_stdlib>
using namespace metal;

constant float START_SPEED = 2.7;
constant float MELT_SPEED = 1;

struct VertexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex VertexOut main_vertex(constant float3 *positions [[ buffer(0) ]],
                             constant float2 *textureCoordinates [[ buffer(1) ]],
                             uint vertexID [[ vertex_id ]]) {
    VertexOut out {
        .position = float4(positions[vertexID], 1),
        .textureCoordinate = textureCoordinates[vertexID],
    };
    return out;
}

/// Adaptation of the Doom Effect shader from: https://www.shadertoy.com/view/XtlyDn
/// Created by k_kondrak in 2017-09-02
fragment float4 doom_melt(texture2d<float> from [[ texture(0) ]],
                          texture2d<float> to [[ texture(1) ]],
                          sampler sampler [[ sampler(0) ]],
                          VertexOut vertexIn [[ stage_in ]],
                          constant float &timePassed [[ buffer(0) ]]) {
    float2 uv = vertexIn.textureCoordinate;
    float velocity = START_SPEED * timePassed;
    if (velocity > 1) velocity = 1;

    uv.y -= velocity * 0.35 * fract(sin(dot(float2(uv.x, 0), float2(12.9898, 78.233))) * 43758.5453);

    if (velocity == 1) uv.y -= MELT_SPEED * (timePassed - velocity / START_SPEED);

    if (uv.y < 0) {
        return to.sample(sampler, vertexIn.textureCoordinate);
    }

    return from.sample(sampler, uv);
}
