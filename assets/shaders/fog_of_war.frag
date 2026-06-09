#version 460 core

uniform vec2 u_resolution;
uniform vec2 u_playerPos; // Coordenadas del jugador normalizadas (0.0 a 1.0)
uniform float u_time;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    
    // Distancia al jugador
    float dist = distance(uv, u_playerPos);
    
    // Crear el radio de visión (la linterna)
    float light = smoothstep(0.3, 0.1, dist);
    
    // Efecto de atmósfera: ruido simple
    float noise = fract(sin(dot(uv + u_time * 0.1, vec2(12.9898, 78.233))) * 43758.5453);
    
    // Color base (noche/oscuridad)
    vec3 baseColor = vec3(0.05, 0.05, 0.08);
    
    // Combinar luz y oscuridad
    vec3 color = mix(baseColor, vec3(1.0, 0.9, 0.7), light * 0.8);
    
    // Aplicar ruido tenue
    color -= noise * 0.05;
    
    fragColor = vec4(color, 1.0);
}