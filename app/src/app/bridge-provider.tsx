import { createContext, useContext, useState } from "react"

export interface BridgeContext {
  inputAmount: string
  onChangeInput: (val: string) => void
}

export const BridgeProviderContext = createContext<BridgeContext>({
  inputAmount: "0",
  onChangeInput: () => {},
})

export const useBridge = () => useContext(BridgeProviderContext)

export function BridgeProvider(props: { children: any }) {
  const [inputAmount, setInputAmount] = useState("0")

  const onChangeInput = (val: string) => {
    setInputAmount(val)
  }

  return (
    <BridgeProviderContext.Provider
      value={{
        inputAmount,
        onChangeInput,
      }}
    >
      {props.children}
    </BridgeProviderContext.Provider>
  )
}
