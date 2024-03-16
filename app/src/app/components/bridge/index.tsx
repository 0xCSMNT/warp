import { Input } from "./components/input"
import { Quote } from "./components/quote"

import { useBridge } from "@/app/bridge-provider"

export function Bridge() {
  const {
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
  } = useBridge()
  console.log(isApproved)
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
      {!isLoading && quote && (
        <Quote amount={quote.outputAmount} amountUsd={quote.outputAmountUsd} />
      )}
      <div
        className="flex h-13 bg-element w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer text-white"
        onClick={onApprove}
      >
        {isApproving ? "Approving..." : isApproved ? "Approved" : "Approve"}
      </div>
      <div
        className="flex h-13 bg-highlight w-full items-center p-4 justify-center rounded-full text-xl font-base cursor-pointer"
        onClick={onSubmit}
      >
        {isSubmitting && (
          <div className="h-3 w-3 mr-4">
            <span className="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-background opacity-75"></span>
          </div>
        )}
        <div>{isSubmitting ? "Submitting..." : "Submit"}</div>
      </div>
    </div>
  )
}
