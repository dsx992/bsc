

int add(int a, int b)
{
        return a + b;
}

int fold(int (*f)(int, int), int *xs, unsigned int size, int ne)
{
        int accum = ne;

        for(int i = 0; i < size; i++)
        {
                accum = f(accum, xs[i]);
        }

        return accum;
}

int main()
{
        int xs[] = {1, 2, 3, 4};

        return fold(add, xs, 4, 0);
}
