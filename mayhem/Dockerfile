FROM ghcr.io/evanrichter/cargo-fuzz as builder

ADD . /ressa
WORKDIR /ressa/fuzz
RUN cargo +nightly fuzz build 

FROM debian:bookworm
COPY --from=builder /ressa/fuzz/target/x86_64-unknown-linux-gnu/release/ressa-fuzz /