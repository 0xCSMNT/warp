import React from "react"

interface PopupProps {
  children: React.ReactNode
  isOpen: boolean
  onClose: () => void
}

export function Popup({ children, isOpen, onClose }: PopupProps) {
  return (
    <div
      className={`backdrop-blur fixed inset-0 z-50 flex items-center justify-center bg-background bg-opacity-80 transition-opacity ${
        isOpen
          ? "opacity-100 pointer-events-auto"
          : "opacity-0 pointer-events-none"
      }`}
      onClick={onClose}
    >
      <div>{children}</div>
    </div>
  )
}
