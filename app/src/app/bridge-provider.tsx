import { createContext, useContext, useEffect, useState } from "react"
import { parseUnits } from "viem"

export interface BridgeContext {
  inputAmount: string
  inputAmountUsd: string
  onChangeInput: (val: string) => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  inputAmountUsd: "$0",
  onChangeInput: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

export function BridgeProvider(props: { children: any }) {
  const [inputAmount, setInputAmount] = useState("0")
  const [inputAmountUsd, setInputAmountUsd] = useState("")

  const onChangeInput = (val: string) => {
    setInputAmount(val)
  }

  useEffect(() => {
    const amount = Number(inputAmount)
    const usdPrice = 1
    setInputAmountUsd(`$${amount * usdPrice}`)
  }, [inputAmount])

  useEffect(() => {
    // const amount = parseUnits(inputAmount, 6)
  }, [inputAmount])

  return (
    <BridgeProviderContext.Provider
      value={{
        inputAmount,
        inputAmountUsd,
        onChangeInput,
      }}
    >
      {props.children}
    </BridgeProviderContext.Provider>
  )
}
