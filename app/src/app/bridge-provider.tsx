import { createContext, useContext, useEffect, useState } from "react"
import { parseUnits } from "viem"

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
  onChangeInput: (val: string) => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  inputAmountUsd: "$0",
  isLoading: false,
  quote: null,
  onChangeInput: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

export function BridgeProvider(props: { children: any }) {
  const [inputAmount, setInputAmount] = useState("0")
  const [inputAmountUsd, setInputAmountUsd] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [quote, setQuote] = useState<FormattedQuote | null>(null)

  const onChangeInput = (val: string) => {
    setInputAmount(val)
  }

  useEffect(() => {
    const amount = Number(inputAmount)
    const usdPrice = 1
    setInputAmountUsd(`$${amount * usdPrice}`)
  }, [inputAmount])

  useEffect(() => {
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
        onChangeInput,
      }}
    >
      {props.children}
    </BridgeProviderContext.Provider>
  )
}
