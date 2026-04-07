# Changelog

This changelog follows the same style that I have seen LiveView, Phoenix, and Elixir use in the past. I'll try to make sure that I maintain it - probably should create some sort of automated process for it... who knows. For now - there's only one release so this should be good enough!

## 1.0.1

A small release to just add a sort-of bug fix. When passing `peer_applications: []` to the config, neither `FLAME` nor `FlamePeer` were started on the peer node. This means that any call to the peer node via FLAME was destined to fail, because FLAME never started on the peer and therefore never received the acknowledgement from the terminator on the peer.

This release enforces that the `:peer_applications` value always contains both `:flame` and `:flame_peer`, regardless of what is passed. This enforces that no matter what, FLAME can properly communicate with the peer.

## 1.0.0

This is the first official release! So everything is empty. Read the docs to get started - have fun!

### Bug fixes

### Enhancements

### Deprecations

### Removal of previously deprecated functionality
