import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react"
import {
  Address,
  encodeFunctionData,
  decodeFunctionResult,
  formatUnits,
  parseAbi,
  parseUnits,
} from "viem"
import {
  useAccount,
  usePublicClient,
  useReadContract,
  useWalletClient,
} from "wagmi"

import { inputTokenUsdc, sourceVaultContract } from "@/app/config"
import { SOURCE_VAULT_ABI } from "./source-vault-abi"

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

interface FormattedQuote {
  outputAmount: string
  outputAmountUsd: string
}

export interface BridgeContext {
  inputAmount: string
  inputAmountUsd: string
  isApproved: boolean
  isApproving: boolean
  isLoading: boolean
  isSubmitting: boolean
  quote: FormattedQuote | null
  onApprove: () => void
  onChangeInput: (val: string) => void
  onSubmit: () => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  inputAmountUsd: "$0",
  isApproved: false,
  isApproving: false,
  isLoading: false,
  isSubmitting: false,
  quote: null,
  onApprove: () => {},
  onChangeInput: () => {},
  onSubmit: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

const usdc = inputTokenUsdc
const spender = sourceVaultContract

export function BridgeProvider(props: { children: any }) {
  const { address } = useAccount()
  const publicClient = usePublicClient()
  const { data: walletClient } = useWalletClient()

  const [inputAmount, setInputAmount] = useState("0")
  const [inputAmountUsd, setInputAmountUsd] = useState("")
  const [isApproving, setIsApproving] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [quote, setQuote] = useState<FormattedQuote | null>(null)

  const { data: allowance, refetch } = useReadContract({
    address: usdc,
    abi: parseAbi([
      "function allowance(address owner, address spender) external view returns (uint256)",
    ]),
    functionName: "allowance",
    args: [address as Address, spender],
  })

  const isApproved = useMemo(() => {
    if (isApproving) return false
    const amnt = Number(inputAmount)
    if (amnt <= 0) return false
    const amount = parseUnits(inputAmount, 6)
    console.log(amount, allowance, "allowance", address, spender)
    return allowance ? allowance >= amount : false
  }, [allowance, inputAmount, isApproving])

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
      const hash = await walletClient.writeContract({
        address: usdc,
        abi,
        functionName: "approve",
        args: [spender, amount],
      })
      await publicClient.waitForTransactionReceipt({
        confirmations: 1,
        hash,
      })
      await refetch()
      setIsApproving(false)
    }
    approve()
  }, [inputAmount, publicClient, walletClient])

  const onChangeInput = (val: string) => {
    setInputAmount(val)
  }

  const onSubmit = () => {
    const submitting = async () => {
      setIsSubmitting(true)
      // TODO: submit tx
      await delay(10_000)
      setIsSubmitting(false)
    }
    console.log("submit")
    submitting()
  }

  useEffect(() => {
    const amount = Number(inputAmount)
    const usdPrice = 1
    setInputAmountUsd(`$${amount * usdPrice}`)
    setQuote(null)
  }, [inputAmount])

  useEffect(() => {
    if (!address || !publicClient) return
    const amnt = Number(inputAmount)
    if (amnt <= 0) return
    const amount = parseUnits(inputAmount, 6)
    const fetchQuote = async () => {
      setIsLoading(true)
      const encodedData = encodeFunctionData({
        abi: SOURCE_VAULT_ABI,
        functionName: "deposit",
        args: [amount, address],
      })
      console.log(encodedData)
      const { data } = await publicClient.call({
        account: address,
        data: encodedData,
        to: sourceVaultContract,
      })
      if (data !== undefined) {
        const value = decodeFunctionResult({
          abi: SOURCE_VAULT_ABI,
          functionName: "deposit",
          data,
        })
        const outputAmount = formatUnits(BigInt(value), 6)
        setQuote({
          outputAmount,
          outputAmountUsd: `$${outputAmount}`,
        })
      }
      setIsLoading(false)
    }
    fetchQuote()
    console.log(amount)
  }, [address, inputAmount, publicClient])

  return (
    <BridgeProviderContext.Provider
      value={{
        inputAmount,
        inputAmountUsd,
        isApproved,
        isApproving,
        isLoading,
        isSubmitting,
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
