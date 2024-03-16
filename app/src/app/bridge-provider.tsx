import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react"
import { parseAbi, parseUnits } from "viem"
import { usePublicClient, useWalletClient } from "wagmi"

import { BaseSourceVaultContract, USDC } from "@/app/constants"

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

interface FormattedQuote {
  outputAmount: string
  outputAmountUsd: string
}

export interface BridgeContext {
  inputAmount: string
  inputAmountUsd: string
  isLoading: boolean
  quote: FormattedQuote | null
  onApprove: () => void
  onChangeInput: (val: string) => void
  onSubmit: () => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  inputAmountUsd: "$0",
  isLoading: false,
  quote: null,
  onApprove: () => {},
  onChangeInput: () => {},
  onSubmit: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

export function BridgeProvider(props: { children: any }) {
  const publicClient = usePublicClient()
  const { data: walletClient } = useWalletClient()

  const [inputAmount, setInputAmount] = useState("0")
  const [inputAmountUsd, setInputAmountUsd] = useState("")
  const [isApproving, setIsApproving] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [quote, setQuote] = useState<FormattedQuote | null>(null)

  const onApprove = useCallback(() => {
    if (!publicClient || !walletClient) return
    const amnt = Number(inputAmount)
    if (amnt <= 0) return
    const approve = async () => {
      setIsApproving(true)
      const abi = parseAbi([
        "function approve(address spender, uint256 amount) external returns (bool)",
      ])
      const amount = parseUnits(inputAmount, 6)
      const spender = BaseSourceVaultContract
      const hash = await walletClient.writeContract({
        address: USDC,
        abi,
        functionName: "approve",
        args: [spender, amount],
      })
      await publicClient.waitForTransactionReceipt({
        confirmations: 1,
        hash,
      })
      setIsApproving(false)
    }
    approve()
  }, [inputAmount, publicClient, walletClient])

  const onChangeInput = (val: string) => {
    setInputAmount(val)
  }

  const onSubmit = () => {
    console.log("submit")
  }

  useEffect(() => {
    const amount = Number(inputAmount)
    const usdPrice = 1
    setInputAmountUsd(`$${amount * usdPrice}`)
    setQuote(null)
  }, [inputAmount])

  useEffect(() => {
    const amnt = Number(inputAmount)
    if (amnt <= 0) return
    const amount = parseUnits(inputAmount, 6)
    // TODO: fetch deposit quote
    const fetchQuote = async () => {
      setIsLoading(true)
      await delay(2000)
      setQuote({
        outputAmount: inputAmount,
        outputAmountUsd: `$${inputAmount}`,
      })
      setIsLoading(false)
    }
    fetchQuote()
    console.log(amount)
  }, [inputAmount])

  return (
    <BridgeProviderContext.Provider
      value={{
        inputAmount,
        inputAmountUsd,
        isLoading,
        quote,
        onApprove,
        onChangeInput,
        onSubmit,
      }}
    >
      {props.children}
    </BridgeProviderContext.Provider>
  )
}
