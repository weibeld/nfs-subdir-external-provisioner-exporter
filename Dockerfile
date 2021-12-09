FROM caddy:2.4.6
WORKDIR /root
COPY run.sh .
CMD ["./run.sh"]
