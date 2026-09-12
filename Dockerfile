# ResumeZen — build the Melange targets with OCaml 5.3, run the Hono server on Bun.
# docker build -t resumezen . && docker run -p 4310:4310 -e DATABASE_URL=libsql://... -e DATABASE_AUTH_TOKEN=... resumezen

FROM ocaml/opam:debian-12-ocaml-5.3 AS build
USER root
RUN apt-get update && apt-get install -y --no-install-recommends curl unzip ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
USER opam
WORKDIR /home/opam/app
RUN opam install -y dune melange
COPY --chown=opam:opam package.json bun.lock ./
RUN /root/.bun/bin/bun install --frozen-lockfile
COPY --chown=opam:opam . .
RUN eval $(opam env) && dune build @backend @frontend && \
    mkdir -p frontend/dist/assets && cp frontend/static/index.html frontend/dist/ && cp frontend/static/assets/*.css frontend/dist/assets/ && \
    /root/.bun/bin/bun build _build/default/frontend/output/frontend/src/main.mjs --outfile frontend/dist/assets/app.js --format esm --target browser --minify

FROM oven/bun:1-slim
WORKDIR /app
ENV NODE_ENV=production PORT=4310
COPY --from=build /home/opam/app/_build/default/backend/output ./_build/default/backend/output
COPY --from=build /home/opam/app/frontend/dist ./frontend/dist
COPY --from=build /home/opam/app/node_modules ./node_modules
COPY --from=build /home/opam/app/themes ./themes
COPY --from=build /home/opam/app/skeleton ./skeleton
COPY --from=build /home/opam/app/package.json ./package.json
EXPOSE 4310
CMD ["bun", "_build/default/backend/output/backend/main.mjs"]
