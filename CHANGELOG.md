# Changelog

All notable changes to `ex_unpoly` will be documented in this file.

## Unreleased

Features

- Add X-Up-Evict-Cache and X-Up-Expire-Cache response headers for cache management.
- Add expire_cache/2, evict_cache/2, and keep_cache/1 helper methods for cache control.
- Add context/1 helper to read layer context from X-Up-Context request header.
- Add X-Up-Context response header and put_context/2 helper for updating layer context.
- Add root?/1 and overlay?/1 helpers for layer detection.
- Add X-Up-Open-Layer response header and open_layer/2 helper for forcing overlay layers.
- Add origin_mode/1 and fail_context/1 helpers for experimental request headers.
- Add emit_events/2 helper for emitting JavaScript events to the frontend.
- Add context?/1 helper for checking if layer has context.

## v1.3.0 (2021-06-17)

Features

- Add support for Unpoly v2
- Replace Travis with Github Actions

## v1.2.1 (2020-01-27)

Features

- Expose header helper methods

## v1.2.0 (2019-11-18)

Breaking Changes

- Get current url through phoenix helper
- Only delete cookie when actually set
- Make sure that cookie is accessible by javascript

## v1.1.1 (2019-11-15)

Bug Fixes

- Return string value from target methods.

## v1.1.0 (2019-11-14)

Breaking Changes

- Echo the complete request url instead of only the path.

## v1.0.0 (2019-11-14)

- initial release
