import { ConnectKitButton } from "connectkit"

export function Footer() {
  return (
    <footer className="flex items-end justify-between w-full p-10">
      <div className="italic font-bold text-2xl text-white">warp ⊹</div>
      <ConnectKitButton />
    </footer>
  )
}
