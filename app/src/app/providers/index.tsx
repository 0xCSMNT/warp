"use client"

import React from "react"

import { WagmiProvider, createConfig, http } from "wagmi"
import { arbitrumSepolia, base, baseSepolia } from "wagmi/chains"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { ConnectKitProvider, getDefaultConfig } from "connectkit"

import { chains } from "@/app/config"

import { BridgeProvider } from "./bridge-provider"
import { WithdrawProvider } from "@/app/providers/withdraw-provider"

const config = createConfig(
  getDefaultConfig({
    chains,
    transports: {
      [arbitrumSepolia.id]: http(
        `https://arb-sepolia.g.alchemy.com/v2/${process.env
          .NEXT_PUBLIC_ALCHEMY_ID!}`,
      ),
      [base.id]: http(
        `https://base-mainnet.g.alchemy.com/v2/${process.env
          .NEXT_PUBLIC_ALCHEMY_ID!}`,
      ),
      [baseSepolia.id]: http(
        `https://base-sepolia.g.alchemy.com/v2/${process.env
          .NEXT_PUBLIC_ALCHEMY_ID!}`,
      ),
    },

    // Required API Keys
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,

    appName: "warp",
    // Optional
    appDescription: "warp warp",
    appUrl: "https://warp.xyz", // your app's url
    appIcon: "https://family.co/logo.png", // your app's icon, no bigger than 1024x1024px (max. 1MB)
  }),
)

const queryClient = new QueryClient()

interface ProvidersProps {
  children: React.ReactNode
}

export const Providers = ({ children }: ProvidersProps) => {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider>
          <BridgeProvider>
            <WithdrawProvider>{children}</WithdrawProvider>
          </BridgeProvider>
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}
