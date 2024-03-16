import { arbitrumSepolia, base, baseSepolia } from "wagmi/chains"
import { Chain } from "wagmi/chains"

import {
  BaseSourceVaultContract,
  USDC,
  USDC_ARB_SEPOLIA,
  USDC_BASE_SEPOLIA,
} from "@/app/constants"

// TEST SETUP INSTRUCTIONS
// 1. move whatever chain you wanna use first in the chains array (default chain)
// 2. add source vault address for chain
// 3. add usdc address for chain

export const chains: readonly [Chain, ...Chain[]] | undefined = [
  arbitrumSepolia,
  base,
  baseSepolia,
]

// Config bridging (based on network)
export const sourceVaultContract = BaseSourceVaultContract
export const inputTokenUsdc = USDC_ARB_SEPOLIA
