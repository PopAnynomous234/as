import { createServer } from "node:http";
import { fileURLToPath } from "url";
import { hostname } from "node:os";
import { server as wisp, logging } from "@mercuryworkshop/wisp-js/server";
import Fastify from "fastify";
import fastifyStatic from "@fastify/static";
import fastifyCompress from '@fastify/compress';

import { scramjetPath } from "@mercuryworkshop/scramjet/path";
import { libcurlPath } from "@mercuryworkshop/libcurl-transport";
import { baremuxPath } from "@mercuryworkshop/bare-mux/node";

const publicPath = fileURLToPath(new URL("../public/", import.meta.url));

logging.set_level(logging.NONE);

// 1. SPEED TUNE: Faster DNS & UDP
Object.assign(wisp.options, {
    allow_udp_streams: true, // Set to true for smoother video streaming if network allows
    dns_servers: ["1.1.1.1", "8.8.8.8"], // Standard high-speed DNS
});

const fastify = Fastify({
    serverFactory: (handler) => {
        return createServer()
            .on("request", (req, res) => {
                // Pre-set security headers for Scramjet compatibility
                res.setHeader("Access-Control-Allow-Origin", "*"); 
                res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
                res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
                handler(req, res);
            })
            .on("upgrade", (req, socket, head) => {
                if (req.url.endsWith("/wisp/")) wisp.routeRequest(req, socket, head);
                else socket.end();
            });
    },
});

// 2. COMPRESSION: Shrinks the payload size of HTML/JSON/JS
await fastify.register(fastifyCompress, { 
    global: true,
    encodings: ['br', 'gzip'], 
    threshold: 1024 
});

// 3. CACHING: Make Scramjet/Libcurl scripts load from browser disk (0ms load)
const immutableCache = {
    maxAge: '7d',
    immutable: true,
    lastModified: false,
    etag: true
};

fastify.register(fastifyStatic, {
    root: publicPath,
    decorateReply: true,
    prefix: "/",
});

fastify.register(fastifyStatic, {
    root: scramjetPath,
    prefix: "/scram/",
    decorateReply: false,
    ...immutableCache
});

fastify.register(fastifyStatic, {
    root: libcurlPath,
    prefix: "/libcurl/",
    decorateReply: false,
    ...immutableCache
});

fastify.register(fastifyStatic, {
    root: baremuxPath,
    prefix: "/baremux/",
    decorateReply: false,
    ...immutableCache
});

fastify.setNotFoundHandler((res, reply) => {
    return reply.code(404).type("text/html").sendFile("404.html");
});

// --- Server Lifecycle ---

process.on("SIGINT", () => shutdown());
process.on("SIGTERM", () => shutdown());

function shutdown() {
    console.log("Shutting down...");
    fastify.close();
    process.exit(0);
}

let port = parseInt(process.env.PORT || "10000");

fastify.listen({
    port: port,
    host: "0.0.0.0",
}, (err, address) => {
    if (err) {
        console.error(err);
        process.exit(1);
    }
    console.log(`🚀 Proxy active at ${address}`);
});