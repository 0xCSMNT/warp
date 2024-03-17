import clsx from "clsx"
import { useState } from "react"

import { Deposit } from "@/app/components/bridge/components/deposit"
import { Submitting } from "@/app/components/bridge/components/submitting"
import { Withdraw } from "@/app/components/bridge/components/withdraw"
import { useBridge } from "@/app/providers/bridge-provider"

export function Bridge() {
  const [showDeposit, setShowDeposit] = useState(true)
  const { isSubmitting } = useBridge()

  const toggleDepositWithdraw = (showDeposit: boolean) => {
    setShowDeposit(showDeposit)
  }

  return isSubmitting ? (
    <Submitting />
  ) : (
    <div className="flex flex-col w-[500px] gap-1">
      <div className="flex flex-row gap-4 mb-2 ml-4">
        <div
          className={clsx(
            "text-3xl cursor-pointer",
            showDeposit ? "text-highlight" : "text-white",
          )}
          onClick={() => toggleDepositWithdraw(true)}
        >
          Deposit
        </div>
        <div
          className={clsx(
            "text-3xl cursor-pointer",
            !showDeposit ? "text-highlight" : "text-white",
          )}
          onClick={() => toggleDepositWithdraw(false)}
        >
          Withdraw
        </div>
      </div>
      {showDeposit && <Deposit />}
      {!showDeposit && <Withdraw />}
    </div>
  )
}
