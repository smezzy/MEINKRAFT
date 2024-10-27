#pragma language glsl3

varying vec3 uv;

#ifdef VERTEX
uniform mat4 view;
uniform mat4 model;
uniform mat4 projection;

attribute vec3 TextureCoords;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    uv = TextureCoords;
    return projection * view * model * vec4((vertex_position.xyz) * 1.001 + 0.5, 1.0);
}

#endif

#ifdef PIXEL

uniform sampler2D marker_texture;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex_col = Texel(marker_texture, uv.xy);
    if (tex_col.a == 0) {
        discard;
    }
    return tex_col;
}

#endif