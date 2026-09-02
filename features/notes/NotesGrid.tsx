"use client"

import { memo } from 'react'
import type { Note } from '@/lib/notes'
import NoteCard from './NoteCard'

function NotesGrid({
  notes,
  query,
  onOpen,
  onToggleDone,
  onPin,
  onArchive,
  onDuplicate,
  onTrash,
  onRestore,
  onDeleteForever,
}: {
  notes: Note[]
  query?: string
  onOpen: (id: number) => void
  onToggleDone: (id: number) => void
  onPin: (id: number) => void
  onArchive: (id: number) => void
  onDuplicate: (id: number) => void
  onTrash: (id: number) => void
  onRestore?: (id: number) => void
  onDeleteForever?: (id: number) => void
}) {
  return (
    <div className="notes-grid px-4">
      {notes.map((note) => (
        <NoteCard
          key={note.id}
          note={note}
          query={query}
          onOpen={onOpen}
          onToggleDone={onToggleDone}
          onPin={onPin}
          onArchive={onArchive}
          onDuplicate={onDuplicate}
          onTrash={onTrash}
          onRestore={onRestore}
          onDeleteForever={onDeleteForever}
        />
      ))}
    </div>
  )
}

export default memo(NotesGrid)
