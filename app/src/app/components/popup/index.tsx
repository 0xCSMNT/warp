import React from "react"

interface PopupProps {
  children: React.ReactNode
  isOpen: boolean
  onClose: () => void
}

export function Popup({ children, isOpen, onClose }: PopupProps) {
  return (
    <div
      className={`fixed inset-0 z-50 flex items-center justify-center transition-opacity ${
        isOpen
          ? "opacity-100 pointer-events-auto"
          : "opacity-0 pointer-events-none"
      }`}
    >
      <div
        className="absolute backdrop-blur w-full h-full  bg-background bg-opacity-95 cursor-pointer"
        onClick={onClose}
      ></div>
      <div className="relative z-99">{children}</div>
    </div>
  )
}
