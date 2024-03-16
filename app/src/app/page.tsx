"use client"

import { Footer } from "@/app/components/footer"
import { Vaults } from "@/app/components/vaults"
import { ConnectKitButton } from "connectkit"
import { useAccount } from "wagmi"

export default function Connect() {
  const { isConnected } = useAccount()
  return (
    <main className="flex justify-center items-center w-full h-screen">
      <div className="flex flex-col justify-between items-center h-full w-full">
        <div></div>
        <div>
          {!isConnected && <ConnectKitButton />}
          {isConnected && <Vaults />}
        </div>
        {isConnected && <Footer />}
        {!isConnected && <div></div>}
      </div>
    </main>
  )
}
