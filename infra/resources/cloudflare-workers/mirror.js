export default {
  async fetch(request) {
    const url = new URL(request.url);
    url.hostname = "cache.nixos.org";
    return await fetch(new Request(url, request));
  },
};
