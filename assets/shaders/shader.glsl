#pragma language glsl3

varying vec3 voxel_color;
varying vec3 uv;
varying float shading;
varying float visibility;

#ifdef VERTEX

attribute float TexId;
attribute vec4 PackedData;

int VoxelId = int(PackedData.x*255.0);
int FaceId = int(PackedData.y*255.0);
int AmbientOcclusionId = int(PackedData.z*255.0);
int FlipId = int(PackedData.w*255.0);

uniform mat4 view;
uniform mat4 model;
uniform mat4 projection;

const vec2 uv_coords[4] = vec2[4](
    vec2(0, 0), vec2(0, 1),
    vec2(1, 0), vec2(1, 1)
);

const int uv_indices[24] = int[24](
    1, 0, 2, 1, 2, 3, // even face
    3, 0, 2, 3, 1, 0, // odd face
    3, 1, 0, 3, 0, 2, // even flipped
    1, 2, 3, 1, 0, 2 // odd flipped
);

const float ao_values[4] = float[4](
    0.1, 0.25, 0.5, 1.0
);

const float face_shading[6] = float[6](
    1.0, 0.5,
    0.5, 0.8,
    0.5, 0.8
);


const float density = 0.006;
const float gradient = 10.0;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    int uv_index = gl_VertexID % 6 + ((FaceId & 1) + FlipId * 2)* 6;


    uv.xy = uv_coords[uv_indices[uv_index]];
    uv.z = int(TexId);
    shading = face_shading[FaceId] * ao_values[AmbientOcclusionId];

    vec4 position_relative_to_cam = view * model * vertex_position;
    float distance = length(position_relative_to_cam);
    visibility = exp(-pow((distance*density), gradient));
    visibility = clamp(visibility, 0.0, 1.0);

    return projection * view * model * vertex_position;
}

#endif


#ifdef PIXEL

const vec3 skyColor = vec3(150.0/255.0, 255.0/255.0, 255.0/255.0);
uniform ArrayImage block_textures;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex_color = Texel(block_textures, uv);
    tex_color.rgb *= shading;
    if (tex_color.a == 0) {
        discard;
    }
    tex_color = mix(vec4(skyColor.rgb, 1), tex_color, visibility);
    return tex_color;
}

#endif
