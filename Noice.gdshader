shader_type canvas_item;

// Gonkee's noise textures, original video: https://youtu.be/ybbJz6C9YYA
// this file heavily references https://thebookofshaders.com/
// https://github.com/Gonkee/Gonkees-Shaders/blob/master/noise%20textures.shader

float rand(vec2 coord){
	// prevents randomness decreasing from coordinates too large
	coord = mod(coord, sin(TIME));
	// returns "random" float between 0 and 1
	return fract(sin(dot(coord, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rand2( vec2 coord ) {
	// prevents randomness decreasing from coordinates too large
	coord = mod(coord, sin(TIME));
	// returns "random" vec2 with x and y between 0 and 1
    return fract(sin( vec2( dot(coord,vec2(127.1,311.7)), dot(coord,vec2(269.5,183.3)) ) ) * 43758.5453);
}

void fragment() {
	vec2 coord = UV * 10000.0; //was 10.0 but too small multiplier creates freezing artefacts
	vec4 curr_color = texture(TEXTURE, UV); //read from texture
	float noise;
	noise = rand(coord);
	COLOR = curr_color * vec4(vec3(noise), 1.0); // 0.88 was the blackest in my original palette)
	//COLOR.a = 0.5; // node modulation doesn't work anymore for shader materials???
}