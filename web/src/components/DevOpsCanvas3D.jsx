import { useEffect, useRef } from "react";
import * as THREE from "three";

/**
 * DevOpsCanvas3D — Cyber Midnight Three.js WebGL Visualization
 *
 * Distinctive Cyber Midnight theme:
 * - Background: #090D16
 * - Primary: #22D3EE (Cyan)
 * - Secondary: #A3E635 (Lime)
 * - Subdued Slate / Muted: #64748B, #94A3B8
 *
 * Framing Architecture:
 * - The central coordinator core & orbital rings are positioned below the hero text
 *   at y: -6.5, anchoring the console mockup.
 * - Service nodes are arranged along the left and right flanks (x <= -8.5 and x >= 8.5),
 *   leaving the central text corridor completely unobstructed.
 * - Pipeline bezier curves arc gracefully outward to frame the headline rather than
 *   crossing through it.
 * - Subdued opacity and gentle glow prevent visual fatigue while preserving 3D depth.
 * - Respects prefers-reduced-motion, window resize, and tab visibility.
 */
export const DevOpsCanvas3D = () => {
  const containerRef = useRef(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // Check reduced motion preference
    const prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    // Scene, Camera, Renderer (Cyber Midnight Background #090D16)
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x090d16, 0.02);

    const camera = new THREE.PerspectiveCamera(
      50,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
    camera.position.set(0, 1.0, 30);

    const renderer = new THREE.WebGLRenderer({
      alpha: true,
      antialias: true,
      powerPreference: "high-performance",
    });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setClearColor(0x090d16, 1);
    container.appendChild(renderer.domElement);

    // Group for mouse parallax tilt
    const worldGroup = new THREE.Group();
    scene.add(worldGroup);

    // --- 1. Lower Baseline Coordinator (Deep below hero content at y: -12.5) ---
    // Anchors the telemetry grid under the console mockup, completely clear of text & buttons
    const coreGroup = new THREE.Group();
    coreGroup.position.set(0, -12.5, -4.0);
    worldGroup.add(coreGroup);

    // Core wireframe icosahedron
    const coreGeo = new THREE.IcosahedronGeometry(2.2, 2);
    const coreMat = new THREE.MeshBasicMaterial({
      color: 0x22d3ee, // Cyber Midnight Primary Cyan
      wireframe: true,
      transparent: true,
      opacity: 0.28,
    });
    const coreMesh = new THREE.Mesh(coreGeo, coreMat);
    coreGroup.add(coreMesh);

    // Core inner glowing halo
    const haloGeo = new THREE.SphereGeometry(1.5, 20, 20);
    const haloMat = new THREE.MeshBasicMaterial({
      color: 0x0891b2, // Deep Cyan
      transparent: true,
      opacity: 0.16,
    });
    const haloMesh = new THREE.Mesh(haloGeo, haloMat);
    coreGroup.add(haloMesh);

    // Orbital Rings around baseline coordinator
    const createRing = (radius, tiltX, tiltY, color, opacity = 0.2) => {
      const ringGeo = new THREE.RingGeometry(radius - 0.035, radius + 0.035, 64);
      const ringMat = new THREE.MeshBasicMaterial({
        color: color,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: opacity,
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = tiltX;
      ring.rotation.y = tiltY;
      coreGroup.add(ring);
      return ring;
    };

    const ring1 = createRing(3.2, Math.PI / 3, 0.2, 0x22d3ee, 0.22);
    const ring2 = createRing(4.4, -Math.PI / 4, 0.5, 0xa3e635, 0.18); // Lime accent
    const ring3 = createRing(5.4, Math.PI / 6, -0.4, 0x0891b2, 0.15);

    // --- 2. Flanking Constellation Nodes (Strict Lateral Positioning) ---
    // Positioned exclusively on outer flanks (|x| >= 19.0), leaving a 38-unit wide central corridor
    const nodeCoords = [
      // Left Flank Nodes (Frame left edge of viewport)
      { x: -21.0, y: 6.0, z: -2.0, color: 0x22d3ee, size: 0.85, label: "k8s-ingress" },
      { x: -24.5, y: 1.0, z: -4.0, color: 0x0891b2, size: 0.78, label: "api-gateway" },
      { x: -19.5, y: -4.0, z: -1.0, color: 0xa3e635, size: 0.80, label: "auth-service" },
      { x: -23.0, y: -9.0, z: -3.0, color: 0x22d3ee, size: 0.72, label: "ci-runner" },

      // Right Flank Nodes (Frame right edge of viewport)
      { x: 21.0, y: 6.0, z: -2.0, color: 0x22d3ee, size: 0.85, label: "cloud-lb" },
      { x: 24.5, y: 1.0, z: -4.0, color: 0xa3e635, size: 0.78, label: "monitoring" },
      { x: 19.5, y: -4.0, z: -1.0, color: 0x22d3ee, size: 0.80, label: "db-cluster" },
      { x: 23.0, y: -9.0, z: -3.0, color: 0x0891b2, size: 0.72, label: "argocd-gitops" },
    ];

    const nodeMeshes = [];
    nodeCoords.forEach((n) => {
      const nGeo = new THREE.DodecahedronGeometry(n.size, 1);
      const nMat = new THREE.MeshBasicMaterial({
        color: n.color,
        wireframe: true,
        transparent: true,
        opacity: 0.75,
      });
      const nMesh = new THREE.Mesh(nGeo, nMat);
      nMesh.position.set(n.x, n.y, n.z);
      worldGroup.add(nMesh);

      // Node inner core
      const innerGeo = new THREE.SphereGeometry(n.size * 0.42, 12, 12);
      const innerMat = new THREE.MeshBasicMaterial({
        color: 0xf1f5f9,
        transparent: true,
        opacity: 0.55,
      });
      const innerMesh = new THREE.Mesh(innerGeo, innerMat);
      nMesh.add(innerMesh);

      nodeMeshes.push({ mesh: nMesh, basePos: { ...n } });
    });

    // --- 3. Pipeline Connection Curves (Lateral Flank Routing & Deep Base) ---
    // Connections stay strictly within flanks and deep under the floor
    const pipelineCurves = [];

    // Left flank pipeline curves
    const leftPairs = [
      [nodeCoords[0], nodeCoords[1]],
      [nodeCoords[1], nodeCoords[2]],
      [nodeCoords[2], nodeCoords[3]],
      [nodeCoords[3], { x: -8.0, y: -12.0, z: -3.5, color: 0x22d3ee }],
    ];
    // Right flank pipeline curves
    const rightPairs = [
      [nodeCoords[4], nodeCoords[5]],
      [nodeCoords[5], nodeCoords[6]],
      [nodeCoords[6], nodeCoords[7]],
      [nodeCoords[7], { x: 8.0, y: -12.0, z: -3.5, color: 0x22d3ee }],
    ];

    [...leftPairs, ...rightPairs].forEach(([from, to]) => {
      const p0 = new THREE.Vector3(from.x, from.y, from.z);
      const p3 = new THREE.Vector3(to.x, to.y, to.z);
      const midX = (from.x + to.x) * 0.5;
      const midY = (from.y + to.y) * 0.5;
      const p1 = new THREE.Vector3(midX * 1.08, midY + 0.5, (from.z + to.z) * 0.5);
      const p2 = new THREE.Vector3(midX * 1.05, midY - 0.5, (from.z + to.z) * 0.5);

      const curve = new THREE.CubicBezierCurve3(p0, p1, p2, p3);
      pipelineCurves.push(curve);

      const points = curve.getPoints(28);
      const lineGeo = new THREE.BufferGeometry().setFromPoints(points);
      const lineMat = new THREE.LineBasicMaterial({
        color: from.color,
        transparent: true,
        opacity: 0.22,
      });
      const line = new THREE.Line(lineGeo, lineMat);
      worldGroup.add(line);
    });

    // Cross-mesh structural links within each flank
    const flankLinks = [
      // Left cluster internal mesh
      [0, 2],
      [1, 3],
      // Right cluster internal mesh
      [4, 6],
      [5, 7],
    ];
    flankLinks.forEach(([idxA, idxB]) => {
      const a = nodeCoords[idxA];
      const b = nodeCoords[idxB];
      const linkGeo = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(a.x, a.y, a.z),
        new THREE.Vector3(b.x, b.y, b.z),
      ]);
      const linkMat = new THREE.LineBasicMaterial({
        color: 0x334155,
        transparent: true,
        opacity: 0.18,
      });
      worldGroup.add(new THREE.Line(linkGeo, linkMat));
    });

    // --- 4. Animated Data Packets (Pulsing along outer pipelines) ---
    const packetCount = pipelineCurves.length * 2;
    const packetData = [];
    const packetGeo = new THREE.BufferGeometry();
    const packetPositions = new Float32Array(packetCount * 3);
    const packetColors = new Float32Array(packetCount * 3);

    let pIdx = 0;
    pipelineCurves.forEach((curve, cIdx) => {
      const curveColor = cIdx < 4 ? 0x22d3ee : (cIdx === 5 ? 0xa3e635 : 0x0891b2);
      for (let k = 0; k < 2; k++) {
        const offset = (k / 2) + Math.random() * 0.15;
        const color = new THREE.Color(curveColor);
        packetData.push({
          curveIndex: cIdx,
          progress: offset % 1.0,
          speed: 0.003 + Math.random() * 0.003,
        });

        packetColors[pIdx * 3] = color.r;
        packetColors[pIdx * 3 + 1] = color.g;
        packetColors[pIdx * 3 + 2] = color.b;
        pIdx++;
      }
    });

    packetGeo.setAttribute(
      "position",
      new THREE.BufferAttribute(packetPositions, 3)
    );
    packetGeo.setAttribute("color", new THREE.BufferAttribute(packetColors, 3));

    const packetMat = new THREE.PointsMaterial({
      size: 0.32,
      vertexColors: true,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
    });
    const packetPoints = new THREE.Points(packetGeo, packetMat);
    worldGroup.add(packetPoints);

    // --- 5. Isometric Telemetry Grid Plane (Cyber Midnight Floor) ---
    const gridHelper = new THREE.GridHelper(70, 45, 0x22d3ee, 0x1e293b);
    gridHelper.position.y = -14.0;
    gridHelper.material.transparent = true;
    gridHelper.material.opacity = 0.12;
    worldGroup.add(gridHelper);

    // --- 6. Ambient Dust Particles (Telemetry Field with Spatial Exclusion) ---
    const dustCount = 280;
    const dustGeo = new THREE.BufferGeometry();
    const dustPos = [];
    for (let i = 0; i < dustCount; i++) {
      let x = (Math.random() - 0.5) * 70;
      let y = (Math.random() - 0.5) * 45;
      let z = (Math.random() - 0.5) * 45;
      // Enforce strict exclusion zone: clear central text and buttons corridor
      if (Math.abs(x) < 17.0 && y > -9.0 && y < 11.0) {
        if (x >= 0) x += 17.0;
        else x -= 17.0;
      }
      dustPos.push(x, y, z);
    }
    dustGeo.setAttribute("position", new THREE.Float32BufferAttribute(dustPos, 3));
    const dustMat = new THREE.PointsMaterial({
      color: 0x94a3b8,
      size: 0.07,
      transparent: true,
      opacity: 0.22,
    });
    const dustParticles = new THREE.Points(dustGeo, dustMat);
    worldGroup.add(dustParticles);

    // --- Interaction States: Mouse & Scroll ---
    const mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    const onMouseMove = (e) => {
      mouse.targetX = (e.clientX / window.innerWidth - 0.5) * 2;
      mouse.targetY = (e.clientY / window.innerHeight - 0.5) * 2;
    };
    window.addEventListener("mousemove", onMouseMove, { passive: true });

    let scrollProgress = 0;
    const onScroll = () => {
      const maxScroll =
        document.documentElement.scrollHeight - window.innerHeight || 1;
      scrollProgress = Math.min(1, Math.max(0, window.scrollY / maxScroll));
    };
    window.addEventListener("scroll", onScroll, { passive: true });

    // Handle Window Resize
    const onResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    };
    window.addEventListener("resize", onResize);

    // Tab Visibility
    let isRunning = true;
    const onVisibilityChange = () => {
      isRunning = !document.hidden;
    };
    document.addEventListener("visibilitychange", onVisibilityChange);

    // --- Render Loop ---
    let animationFrameId;
    let clock = new THREE.Clock();

    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);
      if (!isRunning) return;

      clock.getDelta();
      const time = clock.getElapsedTime();

      // Smooth mouse lerp
      mouse.x += (mouse.targetX - mouse.x) * 0.035;
      mouse.y += (mouse.targetY - mouse.y) * 0.035;

      if (!prefersReducedMotion) {
        // Rotate Coordinator Core & Rings
        coreMesh.rotation.y = time * 0.12;
        coreMesh.rotation.x = time * 0.06;

        haloMesh.scale.setScalar(1 + Math.sin(time * 1.8) * 0.04);

        ring1.rotation.z = time * 0.09;
        ring2.rotation.z = -time * 0.07;
        ring3.rotation.z = time * 0.05;

        // Animate Flanking Nodes (gentle subtle float)
        nodeMeshes.forEach((n, idx) => {
          n.mesh.position.y =
            n.basePos.y + Math.sin(time * 1.2 + idx * 0.8) * 0.18;
          n.mesh.rotation.y = time * 0.2 + idx;
          n.mesh.rotation.x = time * 0.1;
        });

        // Advance Data Packets
        const positions = packetGeo.attributes.position.array;
        packetData.forEach((pkt, i) => {
          pkt.progress = (pkt.progress + pkt.speed) % 1.0;
          const curve = pipelineCurves[pkt.curveIndex];
          const pt = curve.getPoint(pkt.progress);
          positions[i * 3] = pt.x;
          positions[i * 3 + 1] = pt.y;
          positions[i * 3 + 2] = pt.z;
        });
        packetGeo.attributes.position.needsUpdate = true;

        // Dust subtle drift
        dustParticles.rotation.y = time * 0.01;
      }

      // Camera responds to scroll and mouse parallax
      // Subtle depth transitions that keep the scene grounded behind the content
      const targetCamY = 3.5 - scrollProgress * 9.0;
      const targetCamZ = 23 - scrollProgress * 5.0;
      const targetCamX = scrollProgress * 2.5;

      camera.position.x += (targetCamX + mouse.x * 2.0 - camera.position.x) * 0.04;
      camera.position.y += (targetCamY - mouse.y * 1.4 - camera.position.y) * 0.04;
      camera.position.z += (targetCamZ - camera.position.z) * 0.04;

      camera.lookAt(0, -scrollProgress * 3.5, 0);

      renderer.render(scene, camera);
    };

    animate();

    // Cleanup
    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onResize);
      document.removeEventListener("visibilitychange", onVisibilityChange);

      if (container && renderer.domElement) {
        container.removeChild(renderer.domElement);
      }
      renderer.dispose();
      scene.clear();
    };
  }, []);

  return (
    <div
      ref={containerRef}
      className="devops-3d-canvas-container"
      aria-hidden="true"
      style={{
        position: "fixed",
        inset: 0,
        width: "100%",
        height: "100%",
        pointerEvents: "none",
        zIndex: 0,
        overflow: "hidden",
      }}
    />
  );
};

export default DevOpsCanvas3D;
