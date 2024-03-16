import { ConnectKitButton } from "connectkit"
import Image from "next/image"

export function ConnectButton() {
  return (
    <ConnectKitButton.Custom>
      {({ isConnected, isConnecting, show, hide, address, ensName, chain }) => {
        return (
          <button onClick={show}>
            <div className="flex cursor-pointer justify-center items-center hover:scale-95">
              <Image
                alt="connect"
                src="/assets/connect-button.svg"
                width={320}
                height={70}
              />
              <div className="absolute text-lg text-background font-medium">
                Connect
              </div>
            </div>
          </button>
        )
      }}
    </ConnectKitButton.Custom>
  )
}
