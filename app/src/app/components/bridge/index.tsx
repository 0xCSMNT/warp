import { Input } from "./components/input"

export function Bridge() {
  return (
    <div className="flex flex-col w-[600px] gap-2">
      <div className="flex flex-row gap-4">
        <div className="text-3xl text-highlight">Deposit</div>
        <div className="text-3xl text-white">Withdraw</div>
      </div>
      <div>
        <Input />
      </div>
      <div className="h-16 bg-element w-full justify-center p-4 text-center rounded-full text-xl font-base cursor-pointer text-white">
        Approve
      </div>
      <div className="h-16 bg-highlight w-full justify-center p-4 text-center rounded-full text-xl font-base cursor-pointer">
        Submit
      </div>
    </div>
  )
}
