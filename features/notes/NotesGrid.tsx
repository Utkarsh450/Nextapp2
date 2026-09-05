"use client"

import { memo } from 'react'
import type { Note } from '@/lib/notes'
import NoteCard from './NoteCard'

function NotesGrid({
  notes,
  query,
  onOpen,
  onToggleTask,
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
  onToggleTask?: (id: number, line: number) => void
  onPin: (id: number) => void
  onArchive: (id: number) => void
  onDuplicate: (id: number) => void
  onTrash: (id: number) => void
  onRestore?: (id: number) => void
  onDeleteForever?: (id: number) => void
}) {
  return (
    <div className="notes-grid px-3.5">
      {notes.map((note, index) => (
        <NoteCard
          key={note.id}
          note={note}
          query={query}
          index={index}
          onOpen={onOpen}
          onToggleTask={onToggleTask}
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
