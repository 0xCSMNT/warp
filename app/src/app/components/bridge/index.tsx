import { Input } from "./components/input"
import { Quote } from "./components/quote"

import { useBridge } from "@/app/bridge-provider"

export function Bridge() {
  const { inputAmount, inputAmountUsd, isLoading, onChangeInput } = useBridge()
  return (
    <div className="flex flex-col w-[500px] gap-1">
      <div className="flex flex-row gap-4 mb-2 ml-4">
        <div className="text-3xl text-highlight cursor-pointer">Deposit</div>
        <div className="text-3xl text-white cursor-pointer">Withdraw</div>
      </div>
      <div>
        <Input
          onChange={onChangeInput}
          isLoading={isLoading}
          value={inputAmount}
          amountUsd={inputAmountUsd}
        />
      </div>
      {!isLoading && <Quote amount={"10"} usd={"$0"} />}
      <div className="flex h-13 bg-element w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer text-white">
        Approve
      </div>
      <div className="flex h-13 bg-highlight w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer">
        Submit
      </div>
    </div>
  )
}
