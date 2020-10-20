#include "ShaderConstants.fxh"
#include "util.fxh"

/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the Read Me.txt contained in the root directory of this shaderpack!

*/

struct PS_Input
{
	float4 position : SV_Position;
	float3 wpos : WPOS;
        float3 rainpos : RAINPOS;

#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float4 fogColor : FOG_COLOR;
#endif
};

struct PS_Output
{
	float4 color : SV_Target;
};

ROOT_SIGNATURE

float3 U2TM(float3 color)
{
	float gamma = 1.25;
	float A = 1.25;
	float B = 0.1;
	float C = 0.6;
	float D = 0.7;
	float E = 0.02;
	float F = 0.6;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	color = pow(color, float(1. / gamma));
	return color;
}

float3 saturation(float3 rgb, float adjustment)
{
    const float3 W = float3(0.2125, 0.7154, 0.0721);
    float3 intensity = float(dot(rgb, W));
    return min( lerp(intensity, rgb, adjustment), float3( 1.0, 1.0, 1.0 ));
}

void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#ifdef BYPASS_PIXEL_SHADER
    PSOutput.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
    return;
#else

#if USE_TEXEL_AA
	float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 );
#else
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a = 1.0f;
#endif

#if USE_ALPHA_TEST
	#ifdef ALPHA_TO_COVERAGE
		#define ALPHA_THRESHOLD 0.05
	#else
		#define ALPHA_THRESHOLD 0.5
	#endif
	if(diffuse.a < ALPHA_THRESHOLD)
		discard;
#endif

#if defined(BLEND)
	diffuse.a *= PSInput.color.a;
#endif

#if !defined(ALWAYS_LIT)
float2 uvl = PSInput.uv1;
uvl.x = lerp(1.0,uvl.x,length(-PSInput.wpos)/RENDER_DISTANCE *25.0);
float4 Light=TEXTURE_1.Sample(TextureSampler1,uvl);
diffuse *=Light;
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = PSInput.color.a;
	#endif	

	diffuse.rgb *= PSInput.color.rgb;
#else
	float2 uv = PSInput.color.xy;
	diffuse.rgb *= lerp(1.0f, TEXTURE_2.Sample(TextureSampler2, uv).rgb*2.0f, PSInput.color.b);
	diffuse.rgb *= PSInput.color.aaa;
	diffuse.a = 1.0f;
#endif

float3 torch = float3( 255.0/255.0, 141.0/255.0, 11.0/255.0 );
diffuse.rgb += torch * max( 0.0, PSInput.uv1.x- 0.5 );

float shadow = smoothstep(0.876,0.869,PSInput.uv1.y);
shadow *= (1.0-PSInput.uv1.x);
float gelap = 0.7;
shadow = lerp(0.0,gelap,shadow);
diffuse.rgb = lerp(diffuse.rgb,float(0),shadow);

diffuse.rgb=U2TM(diffuse.rgb);

float fog = clamp(length(-PSInput.wpos)/ RENDER_DISTANCE*1.25,0.0,1.0);
float3 fog2 = lerp(diffuse.rgb,FOG_COLOR.rgb, fog);
diffuse.rgb = fog2;

diffuse.rgb = saturation( diffuse.rgb, 1.5 );

float side_block = length(PSInput.color.rgb) / 3.;
float side_shadow = lerp( .8, 1., PSInput.uv1.x );
if(PSInput.color.a == 0.) side_block = 1.;
if(PSInput.color.b + PSInput.color.b > PSInput.color.r + PSInput.color.g) side_block = 1.;

if( PSInput.uv1.y < .87 ) {
}else{
if( side_block < .23 ) diffuse.rgb *= side_shadow;
if( side_block < .228 ) diffuse.rgb *= side_shadow;
if( side_block < .226 ) diffuse.rgb *= side_shadow;
}

if(FOG_CONTROL.x<.4&&FOG_CONTROL.x>.1){
if(frac(PSInput.rainpos.y)==0.0||frac(PSInput.rainpos.y)==0.5){
float drain = 1.0-pow(FOG_CONTROL.y,11.0);
float erain = length(PSInput.wpos.xyz)/RENDER_DISTANCE;
diffuse.rgb +=clamp( erain*7.0,0.0,0.5)*drain;
}
}

bool nether = (FOG_COLOR.r > FOG_COLOR.b	&& FOG_COLOR.r < 0.5 && FOG_COLOR.b < 0.2);
if(nether == true){
float3 torch = float3(1.0,0.2,0.05);
diffuse.rgb += torch * max( 0.0, PSInput.uv1.x- 0.5 );

float fog = clamp(length(-PSInput.wpos)/ RENDER_DISTANCE*2.0,0.0,1.0);
float3 fog2 = lerp(diffuse.rgb,FOG_COLOR.rgb, fog);
diffuse.rgb = fog2;
}

#ifdef FOG
	diffuse.rgb = lerp( diffuse.rgb, PSInput.fogColor.rgb, PSInput.fogColor.a );
#endif

	PSOutput.color = diffuse;

#ifdef VR_MODE
	// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to 
	// the lowest 8 bit value.
	PSOutput.color = max(PSOutput.color, 1 / 255.0f);
#endif

#endif // BYPASS_PIXEL_SHADER
}