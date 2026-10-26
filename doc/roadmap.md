# Planned: PostFrameScrollTo

PostFrameScrollTo is not implemented in this release. PostFrameSpotlight rejects
invisible targets instead of silently scrolling or drawing a misplaced mask.

The follow-up should:

1. Locate a mounted target and scroll its enclosing scrollables into view using
   Flutter's ensureVisible behavior, with alignment and duration controls.
2. Await scrolling and a completed layout before mounting or enabling the
   spotlight. Two independent post-frame callbacks are not a sequencing API.
3. Revalidate the final target geometry, including nested viewports and clips.
4. Respect disposal and use the package's shared asynchronous error policy.
5. Define a separate strategy for lazy children that have not been built;
   ensureVisible alone cannot find an unmounted item's RenderObject.

A composed flow should scroll first and present second, with explicit ownership
of cancellation and failure. No fixed delay or speculative mask should be used.
