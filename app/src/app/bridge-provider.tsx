import { createContext, useContext, useEffect, useState } from "react"
import { parseUnits } from "viem"

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

export interface BridgeContext {
  inputAmount: string
  inputAmountUsd: string
  isLoading: boolean
  onChangeInput: (val: string) => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  inputAmountUsd: "$0",
  isLoading: false,
  onChangeInput: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

export function BridgeProvider(props: { children: any }) {
  const [inputAmount, setInputAmount] = useState("0")
  const [inputAmountUsd, setInputAmountUsd] = useState("")
  const [isLoading, setIsLoading] = useState(false)

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
        onChangeInput,
      }}
    >
      {props.children}
    </BridgeProviderContext.Provider>
  )
}
