// scripts/remotion-scaffold.js
// Creates a Remotion scene from a JSON scene description
// Usage: node remotion-scaffold.js scene.json

const fs = require('fs');
const path = require('path');

const sceneFile = process.argv[2] || 'scene.json';
const scene = JSON.parse(fs.readFileSync(sceneFile, 'utf8'));

const template = `
import { AbsoluteFill, useCurrentFrame, interpolate } from 'remotion';
import React from 'react';

export const Scene${scene.id || 'Default'} = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#f2ede4' }}>
      <div style={{
        position: 'absolute', top: '15%', left: '10%', right: '10%',
        backgroundColor: '#ffffff', borderRadius: 24,
        padding: 40, boxShadow: '0 4px 30px rgba(0,0,0,0.05)',
        opacity,
      }}>
        <h2 style={{ fontFamily: 'sans-serif', fontSize: 48, color: '#222' }}>
          ${scene.title || 'Scene Title'}
        </h2>
        <p style={{ fontFamily: 'sans-serif', fontSize: 28, color: '#555', marginTop: 20 }}>
          ${scene.subtitle || 'Subtitle text...'}
        </p>
      </div>
      <div style={{ position: 'absolute', bottom: 60, left: '10%', right: '10%', textAlign: 'center' }}>
        <span style={{ background: '#ff8c42', color: '#fff', padding: '8px 16px', borderRadius: 12, fontSize: 18 }}>
          ${scene.tag || 'Tag'}
        </span>
      </div>
    </AbsoluteFill>
  );
};

export default Scene${scene.id || 'Default'};
`;

fs.writeFileSync('Scene.js', template.trim());
console.log('Remotion scene written to Scene.js for scene:', scene.title || scene.id);
