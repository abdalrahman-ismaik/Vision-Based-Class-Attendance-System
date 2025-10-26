"""
gallery_utils.py
----------------

Utility functions for working with the face gallery used for attendance
matching.  The gallery consists of a set of embeddings and associated
labels (one embedding per training image).  The functions in this
module load the gallery from disk and perform cosine similarity
matching against the gallery to identify faces.

Embeddings are assumed to be floating point vectors of the same
dimension and may be normalised to unit length.  Matching returns
the label of the most similar embedding if its similarity exceeds a
configurable threshold; otherwise ``'unknown'`` is returned.
"""

from __future__ import annotations

import numpy as np
from typing import Tuple, Sequence


def load_gallery(path: str) -> Tuple[np.ndarray, Sequence[str]]:
    """Load the gallery embeddings and labels from a ``.npz`` file.

    The file must contain two arrays: ``embeddings`` and ``labels``.  The
    ``embeddings`` array should be of shape ``(N, D)`` where ``N`` is the
    number of enrolled faces and ``D`` is the embedding dimension.  The
    ``labels`` array should be one-dimensional of length ``N`` containing
    strings (e.g. names or IDs).

    Parameters
    ----------
    path : str
        Path to the ``.npz`` file created by ``enroll.py``.

    Returns
    -------
    Tuple[np.ndarray, Sequence[str]]
        A tuple ``(embeddings, labels)`` ready for matching.
    """
    data = np.load(path, allow_pickle=True)
    embeddings = data['embeddings']
    labels = data['labels'].tolist()
    return embeddings.astype(np.float32), labels


def match_embedding(
    embedding: np.ndarray,
    gallery_embeddings: np.ndarray,
    gallery_labels: Sequence[str],
    threshold: float = 0.35,
) -> Tuple[str, float]:
    """Find the most similar embedding in the gallery using cosine similarity.

    Cosine similarity is computed between the input embedding and each
    gallery embedding.  If the highest similarity exceeds the
    ``threshold``, the corresponding label is returned; otherwise
    ``'unknown'`` is returned along with the similarity value.

    Parameters
    ----------
    embedding : np.ndarray
        The face embedding of shape ``(D,)`` to be matched.
    gallery_embeddings : np.ndarray
        Array of shape ``(N, D)`` containing all enrolled embeddings.
    gallery_labels : Sequence[str]
        List of length ``N`` with labels corresponding to each
        embedding.
    threshold : float, optional
        Minimum similarity required to accept a match.  Values below
        this threshold will result in ``'unknown'``.

    Returns
    -------
    Tuple[str, float]
        The label of the best matching embedding and the similarity
        value.  If no match exceeds ``threshold``, the label will be
        ``'unknown'``.
    """
    # Ensure the input embedding is a 1D vector
    embedding = embedding.astype(np.float32).ravel()

    # Normalise the embedding to unit length if it isn't already
    norm = np.linalg.norm(embedding)
    if norm > 0:
        embedding = embedding / norm

    # Compute cosine similarities by dot product with each gallery
    # embedding.  If gallery embeddings are not normalised, their
    # magnitudes will affect similarity scores; normalising the
    # gallery ahead of time (e.g. when saving) can avoid this.
    sims = gallery_embeddings.dot(embedding)

    # Find the index of the highest similarity
    idx = int(np.argmax(sims)) if sims.size > 0 else -1
    max_sim = float(sims[idx]) if idx >= 0 else -1.0

    if idx >= 0 and max_sim > threshold:
        return gallery_labels[idx], max_sim
    else:
        return 'unknown', max_sim