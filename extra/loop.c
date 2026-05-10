
#define ARRAY_LEN 4

int main()
{
    int arr[ARRAY_LEN] = {1, 2, 3, 4};
    int sum = 0;

    for(int i = 0; i < ARRAY_LEN; i++)
    {
        sum += arr[i];
    }

    return sum;
}
